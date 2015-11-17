class User < ActiveRecord::Base

  ROLES = %w[admin depositor guest]
  
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
        else
          role = "depositor"
        end
      end

    end

    role

  end

  def self.create_with_omniauth(auth)

    # Rails.logger.warn "\n*** auth to yaml"
    # Rails.logger.warn auth.to_yaml

    authname = auth["info"]["name"]

    if ( (auth["provider"] == "shibboleth") &&  (auth["extra"]["raw_info"]["nickname"]) && ( (auth["extra"]["raw_info"]["nickname"]) != "") )
      authname = "#{auth["extra"]["raw_info"]["nickname"]} #{auth["extra"]["raw_info"]["sn"]}"
    end

    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name =  authname
      user.email = auth["info"]["email"]

      if IDB_CONFIG[:local_mode]
        # Rails.logger.info "inside local mode check #{IDB_CONFIG[:local_mode]}"
        user.role = user_role(auth["info"]["email"])
      else
        # Rails.logger.info "failed local mode check #{IDB_CONFIG[:local_mode]}"
        user.role = user_role(auth["uid"])
      end

    end

  end


end
