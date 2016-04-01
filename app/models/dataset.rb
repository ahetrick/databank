require 'fileutils'
require 'date'
require 'open-uri'
require 'net/http'

class Dataset < ActiveRecord::Base
  include ActiveModel::Serialization

  audited except: [:creator_text, :key, :complete, :has_datacite_change, :is_test, :is_import, :updated_at, :embargo], allow_mass_assignment: true
  has_associated_audits

  MIN_FILES = 1
  MAX_FILES = 10000

  validate :published_datasets_must_remain_complete

  has_many :datafiles, dependent: :destroy
  has_many :creators, dependent: :destroy
  has_many :funders, dependent: :destroy
  has_many :related_materials, dependent: :destroy
  accepts_nested_attributes_for :datafiles, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :creators, reject_if: proc { |attributes| (attributes['family_name'].blank? && attributes['institution_name'].blank?) }, allow_destroy: true
  accepts_nested_attributes_for :funders, reject_if: proc { |attributes| (attributes['name'].blank?) }, allow_destroy: true
  accepts_nested_attributes_for :related_materials, reject_if: proc { |attributes| ((attributes['link'].blank?) && (attributes['citation'].blank?)) }, allow_destroy: true

  before_create 'set_key'
  after_create 'store_agreement'
  before_save 'set_primary_contact'
  before_save 'set_version'
  after_save 'remove_invalid_datafiles'
  after_update 'set_datacite_change'

  def to_param
    self.key
  end

  def self.search(search)
    if search

      #start with an empty relation
      search_result = Array.new

      search_terms = search.split(" ")

      search_terms.each do |term|

        clean_term = term.strip.downcase

        if !clean_term.empty?

          #TODO search creators
          term_relations = Dataset.where('lower(title) LIKE :search OR lower(keywords) LIKE :search OR lower(creator_text) LIKE :search OR lower(identifier) LIKE :search OR lower(description) LIKE :search', search: "%#{clean_term}%")

          term_relations.each do |tr|

            search_result << tr

          end # end of term_realtions each do

        end # end of if clean term is not empty
      end # end of search term each do

      Dataset.where(id: search_result.map(&:id))
    else # else of if search
      Dataset.all
    end # end if search
  end

  def to_datacite_xml

    begin

      # creatorArr = self.creator_list.split(";")

      if self.keywords
        keywordArr = self.keywords.split(";")
      end

      contact = Creator.where(dataset_id: self.id, is_contact: true).first
      raise ActiveRecord::RecordNotFound unless contact

      doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0 encoding="UTF-8"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
      resourceNode = doc.first_element_child

      identifierNode = doc.create_element('identifier')
      identifierNode['identifierType'] = "DOI"
      # for imports and post-v1 versions, use specified identifier, otherwise assert v1
      if self.identifier && self.identifier != ''
        identifierNode.content = self.identifier
      else
        identifierNode.content = "#{IDB_CONFIG[:ezid_placeholder_identifier]}#{self.key}_v1"
      end
      identifierNode.parent = resourceNode

      creatorsNode = doc.create_element('creators')
      creatorsNode.parent = resourceNode

      self.creators.each do |creator|
        creatorNode = doc.create_element('creator')
        creatorNode.parent = creatorsNode

        creatorNameNode = doc.create_element('creatorName')

        creatorNameNode.content = "#{creator.family_name.strip}, #{creator.given_name.strip}"
        creatorNameNode.parent = creatorNode

        # ORCID assumption hard-coded here, but in the model there is a field for identifier_scheme
        if creator.identifier && creator.identifier != ""
          creatorIdentifierNode = doc.create_element('nameIdentifier')
          creatorIdentifierNode['schemeURI'] = "http://orcid.org/"
          creatorIdentifierNode['nameIdentifierScheme'] = "ORCID"
          creatorIdentifierNode.content = "#{creator.identifier}"
          creatorIdentifierNode.parent = creatorNode
        end

      end

      titlesNode = doc.create_element('titles')
      titlesNode.parent = resourceNode

      titleNode = doc.create_element('title')
      titleNode.content = self.title || "Dataset Title"
      titleNode.parent = titlesNode

      contributorsNode = doc.create_element('contributors')
      contributorsNode.parent = resourceNode

      contactNode = doc.create_element('contributor')
      contactNode['contributorType'] = "ContactPerson"
      contactNode.parent = contributorsNode

      if contact.family_name && contact.given_name
        contactNameNode = doc.create_element('contributorName')
        contactNameNode.content = "#{contact.family_name}, #{contact.given_name}"
        contactNameNode.parent = contactNode

        if contact.identifier && contact.identifier != ""
          contactIdentifierNode = doc.create_element('nameIdentifier')
          contactIdentifierNode["schemeURI"] = "http://orcid.org/"
          contactIdentifierNode["nameIdentifierScheme"] = "ORCID"
          contactIdentifierNode.content = "#{contact.identifier}"
          contactIdentifierNode.parent = contactNode
        end
      end

      self.funders.each do |funder|
        if (funder.name && funder.name != '') || (funder.identifier && funder.identifer != '')

          funderNode = doc.create_element('contributor')
          funderNode['contributorType'] = "Funder"
          funderNode.parent = contributorsNode

          funderNameNode = doc.create_element('contributorName')
          funderNameNode.content = funder.name ||= '[Name not provided]'
          funderNameNode.parent = funderNode

          if funder.identifier && funder.identifier != ''
            funderIdentifierNode = doc.create_element('nameIdentifier')
            funderIdentifierNode["schemeURI"] = "http://dx.doi.org/"
            funderIdentifierNode["nameIdentifierScheme"] = "DOI"
            funderIdentifierNode.content = "#{funder.identifier}"
            funderIdentifierNode.parent = funderNode
          end
        end
      end


      publisherNode = doc.create_element('publisher')
      publisherNode.content = self.publisher || "University of Illinois at Urbana-Champaign"
      publisherNode.parent = resourceNode

      publicationYearNode = doc.create_element('publicationYear')
      publicationYearNode.content = self.publication_year || Time.now.year
      publicationYearNode.parent = resourceNode

      if self.keywords

        subjectsNode = doc.create_element('subjects')
        subjectsNode.parent = resourceNode

        keywordArr.each do |keyword|
          subjectNode = doc.create_element('subject')
          subjectNode.content = keyword.strip
          subjectNode.parent = subjectsNode
        end

      end

      datesNode = doc.create_element('dates')
      datesNode.parent = resourceNode

      releasedateNode = doc.create_element('date')
      releasedateNode["dateType"] = "Available"
      if self.tombstone_date && self.tombstone_date != ""
        releasedateNode.content = "#{self.release_date.iso8601}/#{self.tombstone_date.iso8601} "
      else
        releasedateNode.content = self.release_date.iso8601 || Date.current().iso8601
      end
      releasedateNode.content = self.release_date.iso8601 || Date.current().iso8601
      releasedateNode.parent = datesNode

      # languageNode = doc.create_element('language')
      # languageNode.content = "en-us"
      # languageNode.parent = resourceNode

      if self.license && !self.license.blank?
        rightsListNode = doc.create_element('rightsList')
        rightsListNode.parent = resourceNode

        rightsNode = doc.create_element('rights')
        rightsNode.content = self.license
        rightsNode.parent = rightsListNode
      end

      if self.description && !self.description.blank?
        descriptionsNode = doc.create_element('descriptions')
        descriptionsNode.parent = resourceNode
        descriptionNode = doc.create_element('description')
        descriptionNode['descriptionType'] = "Abstract"
        descriptionNode.content = self.description
        descriptionNode.parent = descriptionsNode
      end

      resourceTypeNode = doc.create_element('resourceType')
      resourceTypeNode['resourceTypeGeneral'] = "Dataset"
      resourceTypeNode.content = "Dataset"
      resourceTypeNode.parent = resourceNode


      if self.related_materials.count > 0

        ready_count = 0

        relatedIdentifiersNode = doc.create_element('relatedIdentifiers')
        relatedIdentifiersNode.parent = resourceNode

        self.related_materials.each do |material|

          if material.uri && material.uri != ''

            datacite_arr = Array.new

            if material.datacite_list && material.datacite_list != ''
              datacite_arr = material.datacite_list.split(',')
            else
              datacite_arr << 'IsSupplementTo'
            end

            datacite_arr.each do |relationship|
              ready_count = ready_count + 1
              relatedMaterialNode = doc.create_element('relatedIdentifier')
              relatedMaterialNode['relatedIdentifierType'] = material.uri_type || 'URL'
              relatedMaterialNode['relationType'] = relationship
              relatedMaterialNode.content = material.uri
              relatedMaterialNode.parent = relatedIdentifiersNode
            end

          end
        end

        if ready_count == 0
          relatedIdentifiersNode.remove
        end

      end

      return doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)

    rescue StandardError => error

      default_doc = Nokogiri::XML::Document.parse(%Q[<?xml version="1.0 encoding="UTF-8"?><error>Dataset Incomplete.</error>])
      return default_doc.to_xml

    end

  end

  def to_datacite_raw_xml
    Nokogiri::XML::Document.parse(to_datacite_xml).to_xml
  end

  def recovery_serialization
    dataset = self.serializable_hash
    creators = Array.new
    self.creators.each do |creator|
      creators << creator.serializable_hash
    end
    datafiles = Array.new
    self.datafiles.each do |datafile|
      datafiles << datafile.serializable_hash
    end
    funders = Array.new
    self.funders.each do |funder|
      funders << funder.serializable_hash
    end
    materials = Array.new
    self.related_materials do |material|
      materials << material.serializable_hash
    end

    {"idb_dataset" => {"model" => IDB_CONFIG[:model], "dataset" => dataset, "creators" => creators, "funders" => funders, "materials" => materials, "datafiles" => datafiles}}

  end


  def update_datacite_metadata(current_user)

    if Dataset.completion_check(self, current_user) == 'ok'

      user = nil
      password = nil
      host = IDB_CONFIG[:ezid_host]

      if self.is_test?
        user = 'apitest'
        password = 'apitest'
      else
        user = IDB_CONFIG[:ezid_username]
        password = IDB_CONFIG[:ezid_password]
      end

      target = "#{IDB_CONFIG[:root_url_text]}/datasets/#{self.key}"

      metadata = {}
      if [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::RELEASED].include?(self.publication_state)
        metadata['_status'] = 'public'
      elsif [Databank::PublicationState::PermSuppress::FILE, Databank::PublicationState::PermSuppress::METADATA].include?(self.publication_state)
        metadata['_status'] = 'unavailable'
      end

      metadata['_target'] = target

      if [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::RELEASED, Databank::PublicationState::PermSuppress::FILE].include?(self.publication_state)
        metadata['datacite'] = self.to_datacite_xml
      elsif self.publication_state == Databank::PublicationState::PermSuppress::METADATA
        metadata['datacite'] = self.placeholder_metadata
      end

      uri = URI.parse("https://#{host}/id/doi:#{self.identifier}")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(user, password)
      request.content_type = "text/plain;charset=UTF-8"
      request.body = Dataset.make_anvl(metadata)

      sock = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        sock.use_ssl = true
      end

      begin

        response = sock.start { |http| http.request(request) }
        case response
          when Net::HTTPSuccess, Net::HTTPRedirection
            return true

          else
            Rails.logger.warn response.to_yaml
            return false
        end

      rescue Net::HTTPBadResponse, Net::HTTPServerError => error
        Rails.logger.warn error.message
        Rails.logger.warn response.body
      end


    else
      Rails.logger.warn "dataset not detected as complete - #{Dataset.completion_check(self, current_user)}"
      return false
    end

  end

  # making completion_check a class method with passed-in dataset, so it can be used by controller before save
  def self.completion_check(dataset, current_user)
    response = 'ok'
    validation_error_messages = Array.new
    validation_error_message = ""

    if !dataset.title || dataset.title.empty?
      validation_error_messages << "title"
    end

    if dataset.creator_list.empty?
      validation_error_messages << "at least one creator"
    end

    if !dataset.license || dataset.license.empty?
      validation_error_messages << "license"
    end

    contact = nil
    dataset.creators.each do |creator|
      if creator.is_contact?
        contact = creator
      end
    end

    unless contact
      validation_error_messages << "select primary contact (from Description section author list)"
    end

    if contact.nil? || !contact.email || contact.email == ""
      validation_error_messages << "email address for primary long term contact"
    end

    if current_user
      if ((current_user.role != 'admin') && (dataset.release_date && (dataset.release_date > (Date.current + 1.years))))
        validation_error_messages << "a release date no more than one year in the future"
      end
    end

    if dataset.license && dataset.license == "license.txt"
      has_file = false
      if dataset.datafiles
        dataset.datafiles.each do |datafile|
          if datafile.bytestream_name && ((datafile.bytestream_name).downcase == "license.txt")
            has_file = true
          end
        end
      end

      if !has_file
        validation_error_messages << "a license file named license.txt or a different license selection"
      end

    end

    if dataset.identifier && dataset.identifier != ''
      dupcheck = Dataset.where(identifier: dataset.identifier)
      if dupcheck.count > 1
        validation_error_messages << "a unique DOI"
      end
    end

    if dataset.datafiles.count < 1
      validation_error_messages << "at least one file"
    end

    if dataset.embargo && [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA].include?(dataset.embargo)
      if !dataset.release_date || dataset.release_date <= Date.current
        validation_error_messages << "a future release date for delayed publication (embargo) selection"
      end
    end

    if validation_error_messages.length > 0
      validation_error_message << "Required elements for a complete dataset missing: "
      validation_error_messages.each_with_index do |m, i|
        if i > 0
          validation_error_message << ", "
        end
        validation_error_message << m
      end
      validation_error_message << "."

      response = validation_error_message
    end
    response
  end

  def placeholder_metadata
    doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
    resourceNode = doc.first_element_child

    identifierNode = doc.create_element('identifier')
    identifierNode['identifierType'] = "DOI"
    # for imports and post-v1 versions, use specified identifier, otherwise assert v1
    if self.identifier && self.identifier != ''
      identifierNode.content = self.identifier
    else
      identifierNode.content = "#{IDB_CONFIG[:ezid_placeholder_identifier]}#{self.key}_v1"
    end
    identifierNode.parent = resourceNode

    creatorsNode = doc.create_element('creators')
    creatorsNode.parent = resourceNode

    creatorNode = doc.create_element('creator')
    creatorNode.parent = creatorsNode

    creatorNameNode = doc.create_element('creatorName')

    creatorNameNode.content = "University of Illinois at Urbana-Champaign"
    creatorNameNode.parent = creatorNode


    titlesNode = doc.create_element('titles')
    titlesNode.parent = resourceNode

    titleNode = doc.create_element('title')
    titleNode.content = "Removed Dataset"
    titleNode.parent = titlesNode

    publisherNode = doc.create_element('publisher')
    publisherNode.content = self.publisher || "University of Illinois at Urbana-Champaign"
    publisherNode.parent = resourceNode

    publicationYearNode = doc.create_element('publicationYear')
    publicationYearNode.content = self.publication_year || Time.now.year
    publicationYearNode.parent = resourceNode

    descriptionsNode = doc.create_element('descriptions')
    descriptionsNode.parent = resourceNode
    descriptionNode = doc.create_element('description')
    descriptionNode['descriptionType'] = "Other"
    descriptionNode.content = "Dataset has been removed. Contact the Research Data Service of the University of Illinois at Urbana-Champaign with any questions. http://researchdataservice.illinois.edu"
    descriptionNode.parent = descriptionsNode

    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
  end


  def set_datacite_change
    if is_datacite_changed?
      update_column("has_datacite_change", "true")
    end
  end

  def is_datacite_changed?

    self.related_materials.each do |material|
      if material.uri && material.uri != '' && material.changed?
        return true
      end
    end

    self.creators.each do |creator|
      if creator.changed?
        return true
      end
    end

    self.funders.each do |funder|
      if funder.name_changed? || funder.identifier_changed?
        return true
      end
    end

    if self.title_changed? || self.license_changed? || self.description_changed? || self.version_changed? || self.keywords_changed? || self.identifier_changed? || self.publication_year_changed? || self.release_date_changed? || self.embargo_changed?
      return true
    end

    # if we get here, no DataCite-relevant changes have been detected
    return false

  end

  def visibility
    return_string = ""
    case self.hold_state
      when Databank::PublicationState::TempSuppress::METADATA
        return_string = "Private (Curator Hold)"
      when Databank::PublicationState::TempSuppress::FILE
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = "Private (Saved Draft)"
          when Databank::PublicationState::Embargo::FILE
            return_string = "Public description, Private files (Delayed Publication)"
          when Databank::PublicationState::Embargo::METADATA
            return_string = "Private (Delayed Publication)"
          when Databank::PublicationState::PermSuppress::FILE
            return_string = "Public Metadata, Redacted Files"
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = "Redacted"
          else
            return_string = "Public description, Private files (Curator Hold)"
        end

      else
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = "Private (Saved Draft)"
          when Databank::PublicationState::RELEASED
            return_string = "Public (Published)"
          when Databank::PublicationState::Embargo::FILE
            return_string = "Public description, Private files (Delayed Publication)"
          when Databank::PublicationState::Embargo::METADATA
            return_string = "Private (Delayed Publication)"
          when Databank::PublicationState::PermSuppress::FILE
            return_string = "Public Metadata, Redacted Files"
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = "Redacted"
          else
            #should never get here
            return_string = "Unknown, please contact the Research Data Service"
        end
    end

    if self.new_record?
      return_string = "Private (Not Yet Saved)"
    end

    return_string
  end

  def creator_list
    return_list = ""

    self.creators.each_with_index do |creator, i|

      return_list << "; " unless i == 0

      case creator.type_of
        when Creator::PERSON
          return_list << creator.family_name
          return_list << ", "
          return_list << creator.given_name
        when Creator::INSTITUTION
          return_list << creator.institution_name
      end

    end
    return_list

  end

  def plain_text_citation

    if self.creator_list == ""
      creator_list = "[Creator List]"
    else
      creator_list = self.creator_list
    end

    if title && title != ""
      citationTitle = title
    else
      citationTitle = "[Title]"

    end

    citation_id = (identifier && !identifier.empty?) ? "http://dx.doi.org/#{identifier}" : ""

    return "#{creator_list} (#{publication_year}): #{citationTitle}. #{publisher}. #{citation_id}"
  end

  def set_key
    self.key ||= generate_key
  end

  ##
  # Generates a guaranteed-unique key, of which there are
  # 36^KEY_LENGTH available.
  #
  def generate_key
    proposed_key = nil

    while true

      num_part = rand(10 ** 7).to_s.rjust(7, '0')
      proposed_key = "#{IDB_CONFIG[:key_prefix]}-#{num_part}"
      break unless self.class.find_by_key(proposed_key)
    end
    proposed_key
  end

  def set_primary_contact
    self.corresponding_creator_name = nil
    self.corresponding_creator_email = nil

    self.creators.each do |creator|
      if creator.is_contact?
        self.corresponding_creator_name = "#{creator.given_name} #{creator.family_name}"
        self.corresponding_creator_email = creator.email
      end
    end
  end

  def set_version
    if !self.version
      self.version = "1"
    end
  end


  def remove_invalid_datafiles
    self.datafiles.each do |datafile|
      if (!datafile.medusa_path || datafile.medusa_path == "") && (!datafile.binary.path || datafile.binary.path == "")
        datafile.destroy
      end
    end
  end

  def published_datasets_must_remain_complete
    if publication_state != Databank::PublicationState::DRAFT
      if !title || title == ''
        errors.add(:title, "must be present in a published dataset")
      end
      #TODO for completeness, add attributes not editable by depostors in interface
    end
  end

  def store_agreement
    dir_text = "#{IDB_CONFIG[:agreements_root_path]}/#{self.key}"
    Dir.mkdir dir_text
    FileUtils.chmod "u=wrx,go=rx", File.dirname(dir_text)
    path = "#{dir_text}/deposit_agreement.txt"
    base_content = File.read("#{IDB_CONFIG[:agreements_root_path]}/new/deposit_agreement.txt")
    agent_text = "License granted by #{self.depositor_name} on #{self.created_at.iso8601}\n\n"
    agent_text << "=================================================================================================================\n\n"
    agent_text << "  Are you a creator of this dataset or have you been granted permission by the creator to deposit this dataset?\n"
    agent_text << "  [x] Yes\n\n"
    agent_text << "  Have you removed any private, confidential, or other legally protected information from the dataset?\n"
    agent_text << "  [#{self.removed_private=='yes' ? 'x' : '  ' }] Yes\n"
    agent_text << "  [#{self.removed_private=='no' ? 'x' : '  ' }] No\n"
    agent_text << "  [#{self.removed_private=='na' ? 'x' : '  ' }] N/A\n\n"
    agent_text << "  Do you agree to the Illinois Data Bank Deposit Agreement in its entirety?\n"
    agent_text << "  [x] Yes\n\n"
    agent_text << "================================================================================================================="
    content = "#{agent_text}\n\n#{base_content}"
    File.open(path, "w+") do |f|
      f.write(content)
    end
    FileUtils.chmod "u=wrx,go=rx", path
  end

  def send_incomplete_1m
    notification = DatabankMailer.dataset_incomplete_1m(self.key)
    notification.deliver_now
  end

  def send_embargo_approaching_1m
    notification = DatabankMailer.embargo_approaching_1m(self.key)
    notification.deliver_now
  end

  def send_embargo_approaching_1w
    notification = DatabankMailer.embargo_approaching_1w(self.key)
    notification.deliver_now
  end

  def full_changelog
    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', self.id, self.id)
    changesArr = Array.new
    changes.each do |change|
      agent = nil
      user = nil
      if change.user_id && change.user_id != ''
        user = User.find(Integer(change.user_id))
      end
      if user
        agent = user.serializable_hash
      else
        agent = {"user_id" => change.user_id}
      end
      changesArr << {"change" => change, "agent" => agent}
    end
    changesHash = {"changes" => changesArr, "model" => "#{IDB_CONFIG[:model]}"}
    changesHash
  end

  def self.make_anvl(metadata)
    anvl = ""
    metadata_count = metadata.count
    metadata.each_with_index do |(n, v), i|
      anvl << Dataset.anvl_escape(n.to_s) << ": " << Dataset.anvl_escape(v.to_s)
      if ((i+1) < metadata_count)
        anvl << "\n"
      end
      anvl.force_encoding("UTF-8")
    end
    anvl
  end

  def self.anvl_escape(s)
    URI.escape(s, /[%:\n\r]/)
  end


end
