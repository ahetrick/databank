require 'open-uri'
require 'json'

class User < ActiveRecord::Base
  include ActiveModel::Serialization

  ROLES = %w[admin depositor guest no_deposit]

  validates_uniqueness_of :uid, allow_blank: false
  validates :email, allow_blank: false, email: true

  def netid
    self.uid.split('@').first
  end

  def net_id
    self.netid
  end

  def is? (requested_role)
    self.role == requested_role.to_s
  end

  def self.user_role(uid)

    role = "guest"

    if uid.respond_to?(:split)

      netid = uid.split('@').first

      if netid.respond_to?(:length) && netid.length > 0

        admins = IDB_CONFIG[:admin_list].split(", ")

        if admins.include?(netid)
          role = "admin"
        elsif can_deposit(netid)
          role = "depositor"
        else
          role = "no_deposit"
        end
      end

    end

    role

  end

  def update_with_omniauth(auth)

    # Rails.logger.warn(auth)

    self.provider = auth["provider"]
    self.uid = auth["uid"]
    self.email = auth["info"]["email"]
    self.username = self.email.split('@').first
    self.name = User.user_display_name(self.username)

    if IDB_CONFIG[:local_mode]
      # Rails.logger.info "inside local mode check #{IDB_CONFIG[:local_mode]}"
      self.role = User.user_role(auth["info"]["email"])
    else
      # Rails.logger.info "failed local mode check #{IDB_CONFIG[:local_mode]}"
      # Rails.logger.warn "auth: #{auth.to_yaml}"
      self.role = User.user_role(auth["uid"])
    end
  end

  def self.create_system_user
    create! do |user|
      user.provider = "system"
      user.uid = IDB_CONFIG[:system_user_email]
      user.name = IDB_CONFIG[:system_user_name]
      user.email = IDB_CONFIG[:system_user_email]
      user.username = IDB_CONFIG[:system_user_name]
      user.role = "admin"
    end
  end

  def self.create_with_omniauth(auth)

    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.email = auth["info"]["email"]
      user.username = (auth["info"]["email"]).split('@').first
      user.name = User.user_display_name((auth["info"]["email"]).split('@').first)

      if IDB_CONFIG[:local_mode]
        # Rails.logger.info "inside local mode check #{IDB_CONFIG[:local_mode]}"
        user.role = user_role(auth["info"]["email"])
      else
        # Rails.logger.info "failed local mode check #{IDB_CONFIG[:local_mode]}"
        # Rails.logger.warn "auth: #{auth.to_yaml}"
        user.role = user_role(auth["uid"])
      end

    end

  end

  def self.can_deposit(netid)

    # exception for Patrick Brown, former faculty who still has some datasets to deposit.
    if netid == 'pjb34'
      return TRUE
    end

    # exception for Neil Smalheiser, UIC faculty who is also Affiliated Faculty with the iSchool at Illinois
    if netid == 'neils'
      return TRUE
    end

    response = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
    # Rails.logger.warn response
    # response_nospace = response.gsub(">\r\n", "")
    #response_nospace = response_nospace.gsub("> ", "") while response_nospace.include?("> ")
    #response_noslash = response_nospace.gsub("\"", "'")
    xml_doc = Nokogiri::XML(response)
    xml_doc.remove_namespaces!
    # Rails.logger.warn xml_doc.to_xml
    employee_type = xml_doc.xpath("//attr[@name='uiuceduemployeetype']").text()
    employee_type.strip!
    # Rails.logger.warn "netid then employee type:"
    # Rails.logger.warn netid
    # Rails.logger.warn employee_type
    case employee_type
    when "A"
      # Faculty
      return true
    when "B"
      # Acad. Prof."
      return true
    when "C", "D"
      # Civil Service"
      return true
    when "E"
      # Extra Help"
      return false
    when "G"
      # Grad. Assisant"
      return true
    when "H"
      # Acad./Grad. Hourly"
      return true
    when "L"
      # Lump Sum"
      return false
    when "M"
      # Summer Help"
      return false
    when "P"
      # Post Doc."
      return true
    when "R"
      # Medical Resident"
      return true
    when "S"
      # Student"
      student_level = xml_doc.xpath("//attr[@name='uiucedustudentlevelcode']").text()
      student_level.strip!
      if student_level == "1U"
        # undergraduate
        return false
      else
        return true
      end
    when "T"
      # Retiree"
      return true
    when "U"
      # Unpaid"
      return false
    when "V"
      # Virtual"
      return false
    when "W"
      # One Time Pay"
      return false
    else
      return false
    end

  end

  def self.user_info_string(netid)

    begin

      return("#{self.user_display_name(netid)} | #{netid}@illinois.edu")

    rescue StandardError

      return netid

    end

  end

  def self.reserve_doi_user()

    user = User.new(provider: "system",
                    uid: IDB_CONFIG[:reserve_doi_netid],
                    email: "#{IDB_CONFIG[:reserve_doi_netid]}@illinois.edu",
                    username: IDB_CONFIG[:reserve_doi_netid],
                    name: IDB_CONFIG[:reserve_doi_netid],
                    role: "admin")

    user

  end

  def self.user_display_name(netid)

    # exception for Neil Smalheiser, UIC faculty who is also Affiliated Faculty with the iSchool at Illinois
    if netid == 'neils'
      return "Neil Smalheiser"
    else

      begin

        response = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
        xml_doc = Nokogiri::XML(response)
        xml_doc.remove_namespaces!
        display_name = xml_doc.xpath("//attr[@name='displayname']").text()
        display_name.strip!

        return display_name

        catch OpenURI::HTTPError

        return "Guest"

      end


    end

  end


end
