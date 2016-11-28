require 'fileutils'
require 'date'
require 'open-uri'
require 'net/http'
require 'securerandom'

class Dataset < ActiveRecord::Base
  include ActiveModel::Serialization
  include Datacite
  include Recovery
  include MessageText

  audited except: [:creator_text, :key, :complete, :is_test, :is_import, :updated_at, :embargo], allow_mass_assignment: true
  has_associated_audits

  MIN_FILES = 1
  MAX_FILES = 10000

  validate :published_datasets_must_remain_complete

  has_many :datafiles, dependent: :destroy
  has_many :creators, dependent: :destroy
  has_many :funders, dependent: :destroy
  has_many :related_materials, dependent: :destroy
  has_many :deckfiles, dependent: :destroy
  accepts_nested_attributes_for :datafiles, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :deckfiles, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :creators, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :funders, reject_if: proc { |attributes| (attributes['name'].blank?) }, allow_destroy: true
  accepts_nested_attributes_for :related_materials, reject_if: proc { |attributes| ((attributes['link'].blank?) && (attributes['citation'].blank?)) }, allow_destroy: true

  before_create 'set_key'
  after_create 'store_agreement'
  before_save 'set_primary_contact'
  after_save 'remove_invalid_datafiles'
  before_destroy 'destroy_audit'

  def to_param
    self.key
  end

  def publication_year
    if self.release_date
      self.release_date.year || Time.now.year
    else
      Time.now.year
    end

  end

  # assumes complete dataset
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
            funderIdentifierNode["schemeURI"] = "https://doi.org/"
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

      versionNode = doc.create_element('version')
      versionNode.content = self.dataset_version || "1"
      versionNode.parent = resourceNode

      if self.license && !self.license.blank?
        rightsListNode = doc.create_element('rightsList')
        rightsNode = doc.create_element('rights')

        case self.license

          when "CC01"

            rightsNode["rightsURI"] = "https://creativecommons.org/publicdomain/zero/1.0/"
            rightsNode.content = "CC0 1.0 Universal Public Domain Dedication (CC0 1.0)"
            rightsNode.parent = rightsListNode
            rightsListNode.parent = resourceNode

          when "CCBY4"

            rightsNode["rightsURI"] = "http://creativecommons.org/licenses/by/4.0/"
            rightsNode.content = "Creative Commons Attribution 4.0 International (CC BY 4.0)"
            rightsNode.parent = rightsListNode
            rightsListNode.parent = resourceNode

          when "deposit_agreement.txt"

            rightsNode.content = "See deposit_agreement.txt in dataset"
            rightsNode.parent = rightsListNode
            rightsListNode.parent = resourceNode

          else
            Rails.logger.warn "Unexpected license value #{self.license} for dataset #{self.key}"
        end


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

  def today_downloads
    DayFileDownload.where(dataset_key: self.key).uniq.pluck(:ip_address).count
  end

  def total_downloads
    DatasetDownloadTally.where(dataset_key: self.key).sum :tally
  end

  def dataset_download_tallies
    DatasetDownloadTally.where(dataset_key: self.key)
  end

  def ip_downloaded_dataset_today(request_ip)
    #Rails.logger.warn 'DayFileDownload.where(["ip_address = ? and dataset_key = ? and download_date = ?", request_ip, self.key, Date.current])'
    #Rails.logger.warn DayFileDownload.where(["ip_address = ? and dataset_key = ? and download_date = ?", request_ip, self.key, Date.current]).to_yaml
    DayFileDownload.where(["ip_address = ? and dataset_key = ? and download_date = ?", request_ip, self.key, Date.current]).count > 0
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

  # making completion_check a class method with passed-in dataset, so it can be used by controller before save
  def self.completion_check(dataset, current_user)
    response = 'ok'
    validation_error_messages = Array.new
    validation_error_message = ""

    datafilesArr = Array.new

    if !dataset.title || dataset.title.empty?
      validation_error_messages << "title"
    end

    if dataset.creators.count < 1
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

    dataset.creators.each do |creator|
      if !creator.email || creator.email == ''
        validation_error_messages << "an email address for #{creator.given_name} #{creator.family_name}"
      elsif creator.email.include?('@illinois.edu')
        netid = creator.email.split('@').first

        creator_record = nil

        #check to see if netid is found, to prevent email system errors
        begin

        creator_record = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read

        rescue OpenURI::HTTPError => err
          validation_error_messages << "a valid email address for #{creator.given_name} #{creator.family_name} (please check and correct the netid)"
        end

      end
    end

    dataset.creators.each do |creator|
      if !creator.given_name || creator.given_name == ''
        validation_error_messages << "at least one given name for author(s)"
        break
      end
    end

    dataset.creators.each do |creator|
      if !creator.given_name || creator.given_name == ''
        validation_error_messages << "a family name for author(s)"
        break
      end
    end

    unless contact
      validation_error_messages << "select primary contact from author list"
    end

    if current_user
      if ((current_user.role != 'admin') && (dataset.release_date && (dataset.release_date > (Date.current + 1.years))))
        validation_error_messages << "a release date no more than one year in the future"
      end
    end

    if dataset.license && dataset.license == "deposit_agreement.txt"
      has_file = false
      if dataset.datafiles
        dataset.datafiles.each do |datafile|
          if datafile.bytestream_name && ((datafile.bytestream_name).downcase == "deposit_agreement.txt")
            has_file = true
          end
        end
      end

      if !has_file
        validation_error_messages << "a license file named deposit_agreement.txt or a different license selection"
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
    else
      dataset.datafiles.each do |datafile|
        datafilesArr << datafile.bytestream_name
      end

      firstDup = datafilesArr.detect{ |e| datafilesArr.count(e) > 1 }

      if firstDup
        validation_error_messages << "no duplicate filenames (#{firstDup})"
      end

    end

    if dataset.embargo && [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA].include?(dataset.embargo)
      if !dataset.release_date || dataset.release_date <= Date.current
        validation_error_messages << "a future release date for delayed publication (embargo) selection"
      end

    else
      if dataset.release_date && dataset.release_date > Date.current
        validation_error_messages << "a delayed publication (embargo) selection for a future release date"
      end
    end

    if dataset.is_import? && !dataset.identifier
      validation_error_messages << "identifier to import"
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

  def withdrawn_metadata
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

    creatorNameNode.content = "[Redacted]"
    creatorNameNode.parent = creatorNode


    titlesNode = doc.create_element('titles')
    titlesNode.parent = resourceNode

    titleNode = doc.create_element('title')
    titleNode.content = "[Redacted]"
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
    descriptionNode.content = "Removed by Illinois Data Bank curators. Contact us for more information. #{ IDB_CONFIG[:root_url_text] }/help#contact"
    descriptionNode.parent = descriptionsNode

    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
  end

  # Should only be called for a previously released dataset transitioning to Metadata & File embargo
  def embargo_metadata

    if !self.release_date
      raise "missing release date for file and metadata publication delay for dataset #{self.key}"
    elsif self.release_date.to_date < Date.current
      raise "invalid release date for file and metadata publication delay for dataset #{self.key}"
    end

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

    creatorNameNode.content = "[Embargoed]"
    creatorNameNode.parent = creatorNode


    titlesNode = doc.create_element('titles')
    titlesNode.parent = resourceNode

    titleNode = doc.create_element('title')
    titleNode.content = "[This dataset will be available #{self.release_date.iso8601}. Contact us for more information. #{ IDB_CONFIG[:root_url_text] }/help#contact]"
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
    descriptionNode.content = "This dataset will be available #{self.release_date.iso8601}. Contact us for more information. #{ IDB_CONFIG[:root_url_text] }/help#contact"
    descriptionNode.parent = descriptionsNode

    datesNode = doc.create_element('dates')
    datesNode.parent = resourceNode

    releasedateNode = doc.create_element('date')
    releasedateNode["dateType"] = "Available"
    releasedateNode.content = self.release_date.iso8601
    releasedateNode.content = self.release_date.iso8601
    releasedateNode.parent = datesNode

    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
  end

  def visibility
    return_string = ""
    case self.hold_state
      when Databank::PublicationState::TempSuppress::METADATA
        return_string = "Metadata and Files Temporarily Suppressed"
      when Databank::PublicationState::TempSuppress::FILE
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = "Draft"
          when Databank::PublicationState::Embargo::FILE
            return_string = "Metadata Published, Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::Embargo::METADATA
            return_string = "Metadata and Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::PermSuppress::FILE
            return_string = "Metadata Published, Files Withdrawn"
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = "Metadata and Files Withdrawn"
          else
            return_string = "Metadata Published, Files Temporarily Suppressed"
        end

      else
        case self.publication_state
          when Databank::PublicationState::DRAFT
            return_string = "Draft"
          when Databank::PublicationState::RELEASED
            return_string = "Metadata and Files Published"
          when Databank::PublicationState::Embargo::FILE
            return_string = "Metadata Published, Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::Embargo::METADATA
            return_string = "Metadata and Files Publication Delayed (Embargoed)"
          when Databank::PublicationState::PermSuppress::FILE
            return_string = "Metadata Published, Files Withdrawn"
          when Databank::PublicationState::PermSuppress::METADATA
            return_string = "Metadata and Files Withdrawn"
          else
            #should never get here
            return_string = "Unknown, please contact the Research Data Service"
        end
    end

    if self.new_record?
      return_string = "Unsaved Draft"
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

    citation_id = (identifier && !identifier.empty?) ? "https://doi.org/#{identifier}" : ""

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

  def deck_location
    "#{IDB_CONFIG[:ingest_deck_path]}/#{(self.key)}"
  end

  def has_deck_content
    File.directory?(self.deck_location) && !Dir["#{self.deck_location}/*"].empty?
  end

  def deck_filepaths
    if has_deck_content
      return Dir["#{self.deck_location}/*"]
    else
      return nil
    end
  end

  def current_token
    tokens = Token.where("dataset_key = ? AND expires > ?", self.key, DateTime.now)
    if tokens.count == 1
      return tokens.first
    else
      if tokens.count > 1
        tokens.destroy_all
        Rail.logger.warn "unexpected error: more than one current token for dataset #{self.key}"
      end
      return nil
    end
  end

  def new_token
    if current_token
      current_token.destroy
    end
    return Token.create(dataset_key: self.key, identifier: generate_auth_token, expires: (Time.now + 3.days) )
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

  def remove_invalid_datafiles
    begin
      self.datafiles.each do |datafile|
        datafile.destroy unless ( (datafile.binary && datafile.binary.file) || (datafile.medusa_path && datafile.medusa_path != "") )
      end
    rescue StandardError => ex
      # sigh
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

    # agreement may exist during a restoration to database from medusa serialization
    if File.exists? dir_text
      return true
    end

    Dir.mkdir dir_text
    FileUtils.chmod "u=wrx,go=rx", File.dirname(dir_text)
    path = "#{dir_text}/deposit_agreement.txt"
    unless File.exists? "#{IDB_CONFIG[:agreements_root_path]}/new/deposit_agreement.txt"
      if File.exists? "#{IDB_CONFIG[:agreements_root_path]}/new/deposit_agreement.bk"
        FileUtils.cp "#{IDB_CONFIG[:agreements_root_path]}/new/deposit_agreement.bk", "#{IDB_CONFIG[:agreements_root_path]}/new/deposit_agreement.txt"
      else
        raise "deposit agreement template not found"
      end
    end

    base_content = File.read("#{IDB_CONFIG[:agreements_root_path]}/new/deposit_agreement.txt")
    agent_text = "License granted by #{self.depositor_name} on #{self.created_at.iso8601}\n\n"
    agent_text << "=================================================================================================================\n\n"
    agent_text << "  Are you a creator of this dataset or have you been granted permission by the creator to deposit this dataset?\n"
    agent_text << "  [x] Yes\n\n"
    agent_text << "  [ ] No\n\n"
    agent_text << "  Have you removed any private, confidential, or other legally protected information from the dataset?\n"
    agent_text << "  [#{self.removed_private=='yes' ? 'x' : ' ' }] Yes\n"
    agent_text << "  [#{self.removed_private=='no' ? 'x' : ' ' }] No\n"
    agent_text << "  [#{self.removed_private=='na' ? 'x' : ' ' }] N/A\n\n"
    agent_text << "  Do you agree to the Illinois Data Bank Deposit Agreement in its entirety?\n"
    agent_text << "  [x] Yes\n\n"
    agent_text << "  [ ] No\n\n"
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
      change_hash = change.serializable_hash

      change_hash.delete("remote_address")
      change_hash.delete("request_uuid")
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
      changesArr << {"change" => change_hash, "agent" => agent}
    end
    changesHash = {"changes" => changesArr, "model" => "#{IDB_CONFIG[:model]}"}
    changesHash
  end

  def persistent_url
    (self.identifier && !self.identifier.empty?) ? "https://doi.org/#{self.identifier}" : ""
  end

  def stuctured_data

    if self.publication_state == Databank::PublicationState::RELEASED

      return_string = ""

      return_string << %Q[<script type="application/ld+json">{"@context": "http://schema.org", "@type": "Dataset", "name": "#{self.title.gsub('"', '\\"')}"]

      return_string << %Q(, "author": [)

      self.creators.each_with_index do |creator, index|

        return_string << ", " if index > 0

        if creator.identifier && creator.identifier != ""
          return_string << %Q[{"@type": "Person", "name":"#{creator.given_name} #{creator.family_name}", "url":"http://orcid.org/#{creator.identifier}"}]
        else
          return_string << %Q[{"@type": "Person", "name":"#{creator.given_name} #{creator.family_name}"}]
        end

      end
      return_string << "]"

      if self.keywords && self.keywords != ""

        keywordArr = self.keywords.split(";")

          if keywordArr.length > 0

            keyword_commas = ""

            keywordArr.each_with_index do |keyword, i|
              if i != 0
                keyword_commas << ", "
              end
              keyword_commas << keyword.strip
            end

            return_string << %Q[, "keywords": "#{keyword_commas}" ]

          else
            return_string << %Q[, "keywords": "#{keywordArr[0]}" ]
          end

      end

      if self.description
        return_string << %Q[, "description":"#{self.description.gsub('"', '\\"')}"]
      end

      return_string << %Q[, "version":"#{self.dataset_version}"]

      return_string << %Q[, "url":"https://doi.org/#{self.identifier}"]

      return_string << %Q[, "sameAs":"#{IDB_CONFIG[:root_url_text]}/#{self.key}"]

      if self.funders && self.funders.count > 0

        return_string << %Q(, "funder": [)

        self.funders.each_with_index  do |funder, index|
          return_string << ", " if index > 0
          return_string << %Q[{"@type": "Organization", "name":"#{funder.name}", "url":"https://doi.org/#{funder.identifier}"}]
        end
        return_string << "]"
      end

      return_string << %Q[, "citation":"#{self.plain_text_citation.gsub('"', '\\"')}"]

      license_link = nil

      LICENSE_INFO_ARR.each do |license_info|
        if (license_info.code == self.license) && (self.license !='license.txt')
          license_link = license_info.external_info_url
        end
      end

      if license_link
        return_string << %Q[, "license":"#{license_link}"]
      else
        return_string << %Q[, "license":"See license.txt"]
      end

      return_string << %Q[, "includedInDataCatalog":{"@type":"DataCatalog", "name":"Illinois Data Bank", "url":"https://databank.illinois.edu"}]

      return_string << %Q[}</script>]

      return return_string

    else

      return ""

    end

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

  private

  def generate_auth_token
    SecureRandom.uuid.gsub(/\-/,'')
  end

  def destroy_audit
    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', self.id, self.id)
    changes.each do |change|
      change.destroy
    end
  end

end
