require 'fileutils'
require 'date'
require 'open-uri'
require 'uri'
require 'net/http'
require 'securerandom'
require 'concerns/dataset/indexable'
require 'action_pack'
require 'openssl'

class Dataset < ActiveRecord::Base
  include ActiveModel::Serialization
  include Datacite
  include Recovery
  include MessageText
  include Indexable

  audited except: [:creator_text, :key, :complete, :is_test, :is_import, :updated_at, :embargo], allow_mass_assignment: true
  has_associated_audits

  searchable do
    text :title, :description, :subject_text, :keywords, :identifier, :funder_names_fulltext, :grant_numbers_fulltext, :creator_names_fulltext, :filenames_fulltext, :datafile_extensions_fulltext, :publication_year

    string :publication_year
    string :license_code
    string :depositor
    string :depositor_netid
    string :subject_text
    string :depositor_email
    string :visibility_code
    string :dataset_version
    string :funder_codes, multiple: true
    string :grant_numbers, multiple: true
    string :creator_names, multiple: true
    string :filenames, multiple: true
    string :datafile_extensions, multiple: true
    string :hold_state
    string :publication_state
    boolean :is_test
    boolean :is_most_recent_version
    time :ingest_datetime
    time :release_datetime
    time :created_at
    time :updated_at

  end

  MIN_FILES = 1
  MAX_FILES = 10000

  validate :published_datasets_must_remain_complete
  validates :dataset_version, presence: true

  has_many :datafiles, dependent: :destroy
  has_many :creators, dependent: :destroy
  has_many :contributors, dependent: :destroy
  has_many :funders, dependent: :destroy
  has_many :related_materials, dependent: :destroy
  has_many :deckfiles, dependent: :destroy
  has_many :system_files, dependent: :destroy
  has_many :user_abilities, dependent: :destroy

  accepts_nested_attributes_for :datafiles, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :deckfiles, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :creators, reject_if: proc {|attributes| ((attributes['family_name'].blank?) && (attributes['given_name'].blank?) && (attributes['institution_name'].blank?))}, allow_destroy: true
  accepts_nested_attributes_for :contributors, reject_if: proc {|attributes| ((attributes['family_name'].blank?) && (attributes['given_name'].blank?) && (attributes['institution_name'].blank?))}, allow_destroy: true
  accepts_nested_attributes_for :funders, reject_if: proc {|attributes| (attributes['name'].blank?)}, allow_destroy: true
  accepts_nested_attributes_for :related_materials, reject_if: proc {|attributes| ((attributes['link'].blank?) && (attributes['citation'].blank?))}, allow_destroy: true

  before_create :set_key
  after_create :store_agreement
  before_save :set_primary_contact
  before_destroy :remove_system_files
  before_destroy :destroy_audit

  def to_param
    self.key
  end

  def storage_key_dirpart

    if self.identifier && self.identifier != ''
      "DOI-#{(self.identifier).parameterize}"
    else
      raise "Not valid for datasets without identifiers."
    end

  end

  def publish(user)

    self.complete = Dataset.completion_check(self, user) == 'ok'
    return {status: :error_occurred, error_text: Dataset.completion_check(self, user)} unless self.complete

    self.release_date ||= Date.current

    old_publication_state = publication_state

    if (old_publication_state != Databank::PublicationState::DRAFT) && (!identifier || identifier == '')
      return {status: :error_occurred, error_text: "Missing identifier for dataset that is not a draft. Dataset: #{key}"}
    end

    # set publication_state
    if self.embargo && [Databank::PublicationState::Embargo::FILE, Databank::PublicationState::Embargo::METADATA].include?(embargo)
      self.publication_state = self.embargo
    else
      self.publication_state = Databank::PublicationState::RELEASED
    end

    if old_publication_state == Databank::PublicationState::DRAFT && self.publication_state != Databank::PublicationState::DRAFT
      #remove deck directory, if it exists
      if File.exists?(deck_location)
        FileUtils.rm_rf(deck_location)
      end
      # set release date to current if not embargo
      if self.publication_state == Databank::PublicationState::RELEASED
        self.release_date = Date.current
      end
    end

    if Dataset.post_doi_metadata(self, user) && Dataset.post_doi(self, user)
      MedusaIngest.send_dataset_to_medusa(self)

      if IDB_CONFIG[:local_mode] && IDB_CONFIG[:local_mode] == true
        Rails.logger.warn "Dataset #{key} succesfully deposited."
      else
        begin
          notification = DatabankMailer.confirm_deposit(key)
          notification.deliver_now
        rescue StandardError => error
          Rails.logger.warn "Confirmation email not sent for #{key}"
          Rails.logger.warn error.message
          notification = DatabankMailer.confirmation_not_sent(key, error)
          notification.deliver_now
        end
      end
      {status: :ok, old_publication_state: old_publication_state}
    else
      {status: :error_occurred, error_text: "Error in publishing dataset has been logged for review by the Research Data Service."}
    end

  end

  def version_group

    # version group is an array of hashes
    self_version = self.dataset_version.to_i

    if !self_version || self_version < 1
      self_version = 1
    end

    self_version_entry = self.related_version_entry_hash
    self_version_entry[:selected] = true

    version_group_response = {:status => 'ok', :entries => [self_version_entry]}

    # follow daisy chain of previous versions
    current_dataset = self


    current_group_count = 0
    max_group_count = 50

    while current_dataset && current_group_count < max_group_count

      current_group_count = current_group_count + 1

      previous_dataset = current_dataset.previous_idb_dataset

      if previous_dataset == current_dataset
        break
      end

      #Rails.logger.warn "previous_dataset #{previous_dataset}"

      if previous_dataset
        version_group_response[:entries] << previous_dataset.related_version_entry_hash
      end

      # go to next, if it exists, else set control to nil and break
      current_dataset = previous_dataset

    end

    #reset pointer for chain of next versions
    current_dataset = self
    current_group_count = 0

    while current_dataset

      current_group_count = current_group_count + 1

      next_dataset = current_dataset.next_idb_dataset

      if next_dataset == current_dataset
        break
      end

      if next_dataset
        version_group_response[:entries] << next_dataset.related_version_entry_hash

      end

      # go to next, if it exists, else set control to nil and break
      current_dataset = next_dataset

    end

    (version_group_response[:entries].sort_by! {|k| k[:version]}).reverse!
    version_group_response

  end

  def metadata_public?
    [Databank::PublicationState::RELEASED,
     Databank::PublicationState::Embargo::FILE,
     Databank::PublicationState::TempSuppress::FILE,
     Databank::PublicationState::PermSuppress::FILE].include?(publication_state) && hold_state == Databank::PublicationState::TempSuppress::NONE
  end

  def files_public?
    Databank::PublicationState::RELEASED == publication_state && hold_state == Databank::PublicationState::TempSuppress::NONE
  end

  def related_version_entry_hash
    # version group is an array of hashes
    self_version = self.dataset_version.to_i

    if !self_version || self_version < 1
      self_version = 1
    end

    {version: self_version, selected: false, doi: self.identifier || "not yet set", version_comment: self.version_comment || "", publication_date: self.release_date ? self.release_date.iso8601 : "not yet set"}
  end

  def is_most_recent_version

    # Rails.logger.warn (self.version_group[:entries].to_yaml)

    if self.version_group.length > 0
      return (self.version_group[:entries][0])[:version] == self.dataset_version.to_i
    else
      return true
    end

  end


  def previous_idb_dataset
    previous_version_related_material = self.related_materials.find_by_datacite_list(Databank::Relationship::NEW_VERSION_OF)

    if previous_version_related_material && previous_version_related_material.uri
      previous_idb_dataset = Dataset.find_by_identifier(previous_version_related_material.uri)
      return previous_idb_dataset
    else
      return nil
    end

  end

  def next_idb_dataset
    next_version_related_material = self.related_materials.find_by_datacite_list(Databank::Relationship::PREVIOUS_VERSION_OF)

    if next_version_related_material && next_version_related_material.uri
      next_idb_dataset = Dataset.find_by_identifier(next_version_related_material.uri)
      return next_idb_dataset
    else
      return nil
    end

  end

  def publication_year
    if self.release_date
      self.release_date.year || Time.now.year
    else
      Time.now.year
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
    Nokogiri::XML::Document.parse(Dataset.to_datacite_xml(self)).to_xml
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
    response = 'An unexpected exception was raised and logged during completion check.'

    begin
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
          validation_error_messages << "an email address for all creators"
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
        if creator.type_of == Databank::CreatorType::PERSON && (!creator.given_name || creator.given_name == '')
          validation_error_messages << "at least one given name for author(s)"
          break
        end
      end

      dataset.creators.each do |creator|
        if creator.type_of == Databank::CreatorType::PERSON && !creator.given_name || creator.given_name == ''
          validation_error_messages << "a family name for author(s)"
          break
        end
      end

      dataset.creators.each do |creator|
        if creator.type_of == Databank::CreatorType::INSTITUTION && !creator.institution_name || creator.institution_name == ''
          validation_error_messages << "a name for institution(s)"
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
      else
        dataset.datafiles.each do |datafile|
          datafilesArr << datafile.bytestream_name
        end

        firstDup = datafilesArr.detect {|e| datafilesArr.count(e) > 1}

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


    rescue Exception => exception

      # temporary debugging strategy
      # I expect something terrible is happening here at runtime,
      # and my overall rescue of Standard Exception
      # is not catching anything.
      # This is totally the desparate measure it looks like.

      Rails.logger.warn exception.to_yaml

      exception_string = "*** Standard Error caught in application_controller.rb on #{IDB_CONFIG[:root_url_text]} ***\nclass: #{exception.class}\nmessage: #{exception.message}\n"
      exception_string << Time.now.utc.iso8601

      exception_string << "\nstack:\n"
      exception.backtrace.each do |line|
        exception_string << line
        exception_string << "\n"
      end

      Rails.logger.warn(exception_string)

      if current_user
        exception_string << "\nCurrent User: #{current_user.name} | #{current_user.email}"
      end

      notification = DatabankMailer.error(exception_string)
      notification.deliver_now

      raise exception
    else
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
      else
        response = 'ok'
      end
    ensure
      return response || 'error'
    end

  end

  def individual_creators
    self.creators.where(type_of: Databank::CreatorType::PERSON)
  end

  def institutional_creators
    self.creators.where(type_of: Databank::CreatorType::INSTITUTION)
  end

  def creator_list
    if self.creators.count == 0
      return "[Creator List]"
    elsif self.creators.count == 1
      creator = self.creators.first
      if creator.institution_name && creator.institution_name != '' || creator.family_name && creator.family_name != ''
        return creator.list_name
      end
    else
      return_list = ""
      self.creators.each_with_index do |creator, i|
        return_list << "; " unless i == 0
        return_list << creator.list_name
      end
      return return_list
    end
  end

  def contributor_list
    if self.contributors.count == 0
      return nil
    elsif self.contributors.count == 1
      contributor = self.contributors.first
      return contributor.list_name
    else
      return_list = ""
      self.contributors.each_with_index do |contributor, i|
        return_list << ", " unless i == 0
        return_list << contributor.list_name
      end
      return return_list
    end
  end

  def license_name
    license_name = "License not selected"

    LICENSE_INFO_ARR.each do |license_info|
      if (license_info.code == self.license) && (self.license != 'license.txt')
        license_name = license_info.name
      elsif self.license == 'license.txt'
        license_name = 'See license.txt file in dataset.'
      end
    end

    license_name

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
    elsif tokens.count > 1
      tokens.destroy_all
      Rail.logger.warn "unexpected error: more than one current token for dataset #{self.key}"
    else
      return "token"
    end
  end

  def has_expired_token_only
    expired_tokens = Token.where("dataset_key = ? AND expires < ?", self.key, DateTime.now)
    return expired_tokens.count > 0 && self.current_token == "token"
  end

  def current_token_expires
    tokens = Token.where("dataset_key = ? AND expires > ?", self.key, DateTime.now)
    if tokens.count == 1
      return tokens.first
    elsif tokens.count > 1
      tokens.destroy_all
      Rail.logger.warn "unexpected error: more than one current token for dataset #{self.key}"
      return "n/a"
    else
      return "n/a"
    end
  end

  def new_token
    if current_token && current_token != "token"
      current_token.destroy
    end
    return Token.create(dataset_key: self.key, identifier: generate_auth_token, expires: (Time.now + 3.days))
  end

  def set_primary_contact
    self.corresponding_creator_name = nil
    self.corresponding_creator_email = nil

    self.creators.each do |creator|
      if creator.is_contact?
        if creator.type_of == Databank::CreatorType::PERSON
          self.corresponding_creator_name = "#{creator.given_name} #{creator.family_name}"

        elsif creator.type_of == Databank::CreatorType::INSTITUTION
          self.corresponding_creator_name = creator.institution_name
        end
        self.corresponding_creator_email = creator.email
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

  def default_preview_file

    returnfile = nil
    if self.datafiles.count > 0

      self.datafiles.each do |datafile|
        if datafile.bytestream_name.downcase.include?("readme")
          returnfile = datafile
        end
      end
      unless returnfile
        self.datafiles.each do |datafile|

          filename_split = datafile.bytestream_name.split(".")
          if filename_split.count > 1
            if filename_split.last == "txt"
              returnfile = datafile
            end
          end
        end
      end
      unless returnfile
        returnfile = self.datafiles.first
      end

    end

    return returnfile

  end

  def total_filesize

    total = 0

    self.datafiles.each do |datafile|
      total += datafile.bytestream_size
    end

    total

  end

  def num_external_relationships

    external_relationship_count = 0


    self.related_materials.each do |material|

      datacite_arr = Array.new

      if material.datacite_list && material.datacite_list != ''
        datacite_arr = material.datacite_list.split(',')
      end

      datacite_arr.each do |relationship|

        if ['IsPreviousVersionOf', 'IsNewVersionOf'].exclude?(relationship)
          external_relationship_count = external_relationship_count + 1
        end

      end
    end

    return external_relationship_count

  end

  def self.local_zip_max_size
    750000000
  end

  def valid_datafiles
    self.datafiles.where.not(storage_root: [nil, ""]).
        where.not(storage_key: [nil, ""]).
        where.not(binary_size: nil).
        where("binary_size > ?", 0)
  end

  def sorted_datafiles
    valid_datafiles.sort_by {|obj| obj.bytestream_name}
  end

  def complete_datafiles

    datafiles = []
    sorted_datafiles.each do |datafile|
      datafiles << datafile if datafile.has_bytestream && datafile.bytestream_name != "" && datafile.job_status == :complete
    end
    datafiles
  end

  def incomplete_datafiles

    datafiles = []
    sorted_datafiles.each do |datafile|
      datafiles << datafile if datafile.job_status != :complete
    end
    datafiles

  end

  def medusa_ingests
    identifiers = Datafile.where(dataset_id: self.id).pluck(:web_id)
    identifiers.push(self.key)
    MedusaIngest.where(idb_identifier: identifiers)
  end

  def medusa_status
    ingests = medusa_ingests
    return "unknown"
  end

  def fileset_preserved?

    # assume all are preserved unless a file is found that is not preserved

    fileset_preserved = true

    self.datafiles.each do |df|

      if df.storage_root != Application.storage_manager.medusa_root.name
        fileset_preserved = false
      end
    end

    fileset_preserved

  end

  def dirname
    if self.identifier && self.identifier != ""
      "DOI-#{(self.identifier).parameterize}"
    else
      "DRAFT-#{self.key}"
    end
  end

  def draft_agreement_key
    "drafts/#{self.key}/deposit_agreement.txt"
  end

  def medusa_agreement_key
    "#{self.dirname}/system/deposit_agreement.txt"
  end

  def store_agreement

    uri = URI.parse("#{IDB_CONFIG[:root_url_text]}/deposit_agreement.txt")

    base_content = nil

    if IDB_CONFIG[:root_url_text].include?('dev') || IDB_CONFIG[:root_url_text].include?('pilot')
      base_content = open(uri, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
    else
      base_content = uri.read
    end

    agent_text = "License granted by #{self.depositor_name} on #{self.created_at.iso8601}\n\n"
    agent_text << "=================================================================================================================\n\n"
    agent_text << "  Are you a creator of this dataset or have you been granted permission by the creator to deposit this dataset?\n"
    agent_text << "  [x] Yes\n\n"
    agent_text << "  [ ] No\n\n"
    agent_text << "  Have you removed any private, confidential, or other legally protected information from the dataset?\n"
    agent_text << "  [#{self.removed_private == 'yes' ? 'x' : ' ' }] Yes\n"
    agent_text << "  [#{self.removed_private == 'no' ? 'x' : ' ' }] No\n"
    agent_text << "  [#{self.removed_private == 'na' ? 'x' : ' ' }] N/A\n\n"
    agent_text << "  Do you agree to the Illinois Data Bank Deposit Agreement in its entirety?\n"
    agent_text << "  [x] Yes\n\n"
    agent_text << "  [ ] No\n\n"
    agent_text << "================================================================================================================="
    content = "#{agent_text}\n\n#{base_content}"

    Application.storage_manager.draft_root.write_string_to(self.draft_agreement_key, content)
    SystemFile.create(dataset_id: self.id, storage_root: 'draft', storage_key: self.draft_agreement_key, file_type: 'agreement')

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

  def ingest_datetime

    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) ", 'Dataset', self.id)
    changes.each do |change|

      if (change.audited_changes.keys.include?("publication_state"))

        pub_change = (change.audited_changes)["publication_state"]

        if pub_change.class == Array && pub_change[0] == Databank::PublicationState::DRAFT
          return change.created_at
        end

      end
    end
    # if we get here, there was no change in changelog from draft to another state

    if self.publication_state == Databank::PublicationState::DRAFT
      return DateTime.new(1, 1, 1)
    elsif self.release_date && self.release_date > DateTime.new(1, 1, 1)
      return self.release_datetime
    else
      return DateTime.new(1, 1, 1)
    end

  end

  def display_changelog

    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', self.id, self.id)

    medusaChangesArr = Array.new
    publication = nil

    begin

      changes.each do |change|

        if (change.audited_changes.has_key?('medusa_uuid')) || (change.audited_changes.has_key?('binary_name')) || (change.audited_changes.has_key?('medusa_dataset_dir'))
          medusaChangesArr << change.id
        end

        if (change.audited_changes.keys.include?("publication_state"))

          pub_change = (change.audited_changes)["publication_state"]
          if pub_change.class == Array && pub_change[0] == Databank::PublicationState::DRAFT
            publication = change.created_at
            medusaChangesArr << change.id
          end
        end
      end

    rescue StandardError => ex
      raise ex unless ex.message.include?('BinaryUploader')
    end

    if publication
      changes = changes.where("created_at >= ?", publication).where.not(id: medusaChangesArr)
    else
      Rails.logger.warn "no changes found for dataset #{attributes[:dataset_id]}"
      changes = Audited::Adapters::ActiveRecord::Audit.none
    end
    changes.reorder('created_at DESC')

  end

  def full_changelog
    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', self.id, self.id)
    changesArr = Array.new
    changes.each do |change|
      begin
        change_hash = change.serializable_hash

        change_hash.delete("remote_address")
        change_hash.delete("request_uuid")
        agent = nil
        user = nil
        if change.user_id && change.user_id != ''
          user = User::Shibboleth.find(Integer(change.user_id))
        end
        if user
          agent = user.serializable_hash
        else
          agent = {"user_id" => change.user_id}
        end
        changesArr << {"change" => change_hash, "agent" => agent}
      rescue ArgumentError
        Rails.logger.warn("ArgumentError in changelog: #{change.to_yaml}")
      rescue StandardError => ex
        raise ex unless ex.message.include?('BinaryUploader')
      end
    end
    changesHash = {"changes" => changesArr, "model" => "#{IDB_CONFIG[:model]}"}
    changesHash
  end

  def persistent_url
    (self.identifier && !self.identifier.empty?) ? "https://doi.org/#{self.identifier}" : ""
  end

  def license_code

    if self.license && self.license != ''
      if self.license.include?('.txt')
        return 'custom'
      else
        return self.license
      end
    else
      return "unselected"
    end
  end

  def depositor
    if self.depositor_email
      netid = self.depositor_email.split('@').first
      name = User::Shibboleth.user_info_string(self.depositor_email)
      return "#{netid}|#{name}"
    else
      'error'
    end
  end

  def depositor_netid
    if self.depositor_email
      self.depositor_email.split('@').first
    else
      'error'
    end
  end

  def structured_data

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

        self.funders.each_with_index do |funder, index|
          return_string << ", " if index > 0
          return_string << %Q[{"@type": "Organization", "name":"#{funder.name}", "url":"https://doi.org/#{funder.identifier}"}]
        end
        return_string << "]"
      end

      return_string << %Q[, "citation":"#{self.plain_text_citation.gsub('"', '\\"')}"]

      license_link = nil

      LICENSE_INFO_ARR.each do |license_info|
        if (license_info.code == self.license) && (self.license != 'license.txt')
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

  def mine_or_not_mine(email_address)
    if email_address == depositor_email
      return "mine"
    else
      return "not_mine"
    end
  end

  def recordtext

    if !self.identifier || self.identifier == ''
      return "Method not valid for draft dataset."
    end

    content = "##########################################################################################\n"
    content = content + "#  About this file:\n"
    content = content + "#  The dataset described in this info file was downloaded in part or in whole from the Illinois Data Bank.\n"
    content = content + "#  This info file contains citation information, a permanent digital object identifier (DOI),\n"
    content = content + "#  and a listing of all data files available for this dataset.\n"
    content = content + "#  Keep this info file so in the future you'll know where you obtained the data files you've just downloaded.\n"
    content = content + "##########################################################################################\n\n"

    content = content + "[ DOI: ] #{self.identifier}\n"
    content = content + "[ Title: ] #{self.title}\n"
    content = content + "[ #{'Creator'.pluralize(self.creators.count)}: ] #{self.creator_list}\n"
    content = content + "[ Publisher: ] #{self.publisher}\n"
    content = content + "[ Publication Year: ] #{self.publication_year}\n\n"

    content = content + "[ Citation: ] #{self.plain_text_citation}\n\n"

    if self.description && self.description != ''
      content = content + "[ Description: ] #{self.description}\n\n"
    end

    if self.keywords && self.keywords != ''
      content = content + "[ Keywords: ] #{self.keywords}\n"
    end

    case self.license
    when "CC01"
      content = content + "[ License: ] CC0 - https://creativecommons.org/publicdomain/zero/1.0/\n"
    when "CCBY4"
      content = content + "[ License: ] CC BY - http://creativecommons.org/licenses/by/4.0/\n"
    when "license.txt"
      content = content + "[ License: ] Custom - See license.txt file in dataset.\n"
    else
      content = content + "[ License: ] Not found.\n"
    end

    content = content + "[ Corresponding Creator: ] #{self.corresponding_creator_name}\n"

    if self.funders.count > 0

      self.funders.each do |funder|
        content = content + "[ Funder: ] #{funder.name}"
        if funder.grant && funder.grant != ''
          content = content + "- [ Grant: ] #{funder.grant}"
        end
      end

      content = content + "\n"

    end

    if self.related_materials.count > 0

      self.related_materials.each do |material|
        if material.uri && (material.relationship_arr.include?(Databank::Relationship::PREVIOUS_VERSION_OF) || material.relationship_arr.include?(Databank::Relationship::NEW_VERSION_OF))
          # handled in versions section
        elsif material.citation || material.link
          content = content + "[ Related"
          if material.material_type && material.material_type != ""
            content = content + " #{material.material_type}: ] "
          else
            content = content + "Material: ] "
          end

          if material.citation && material.citation != ''
            content = content + "#{material.citation}"
          end

          if material.citation && material.citation != '' && material.link && material.link != ''
            content = content + ", "
          end

          if material.link && material.link != ''
            content = content + "#{material.link}"
          end
        end
      end
    end

    content = content + "\n[ #{'File'.pluralize(self.datafiles.count)} (#{self.datafiles.count}): ] \n"

    self.complete_datafiles.each do |datafile|
      content = content + ". #{datafile.bytestream_name}, #{ApplicationController.helpers.number_to_human_size(datafile.bytestream_size)}\n"
    end

    return content

  end

  def user_abilites
    DatasetUserAbility.where(dataset_key: self.key)
  end

  def ind_creators_to_contributors
    self.individual_creators.each do |creator|
      Contributor.create(dataset_id: creator.dataset_id,
                         given_name: creator.given_name,
                         family_name: creator.family_name,
                         email: creator.email,
                         identifier: creator.identifier,
                         identifier_scheme: creator.identifier_scheme,
                         row_order: creator.row_order,
                         row_position: creator.row_position,
                         type_of: Databank::CreatorType::PERSON)
      creator.destroy
    end
  end

  def contributors_to_ind_creators
    self.contributors.each do |contributor|
      Creator.create(dataset_id: contributor.dataset_id,
                         given_name: contributor.given_name,
                         family_name: contributor.family_name,
                         email: contributor.email,
                         identifier: contributor.identifier,
                         identifier_scheme: contributor.identifier_scheme,
                         row_order: contributor.row_order,
                         row_position: contributor.row_position,
                         type_of: Databank::CreatorType::PERSON)
      contributor.destroy
    end

  end


  def self.make_anvl(metadata)
    anvl = ""
    metadata_count = metadata.count
    metadata.each_with_index do |(n, v), i|
      anvl << Dataset.anvl_escape(n.to_s) << ": " << Dataset.anvl_escape(v.to_s)
      if ((i + 1) < metadata_count)
        anvl << "\n"
      end
      anvl.force_encoding("UTF-8")
    end
    anvl
  end

  def self.anvl_escape(s)
    URI.escape(s, /[%:\n\r]/)
  end

  def review_requests
    ReviewRequest.where(dataset_key: self.key)
  end

  def in_pre_publication_review
    publication_state == Databank::PublicationState::DRAFT && ( (identifier && identifier != '') || review_requests.count > 0)
  end

  private

  def generate_auth_token
    SecureRandom.uuid.gsub(/\-/, '')
  end

  def destroy_audit
    changes = Audited::Adapters::ActiveRecord::Audit.where("(auditable_type=? AND auditable_id=?) OR (associated_id=?)", 'Dataset', self.id, self.id)
    changes.each do |change|
      change.destroy
    end
  end

  def remove_system_files
    root = Application.storage_manager.draft_root
    system_files.each do |system_file|
      if root.exist?(system_file.storage_key)
        root.delete_content(system_file.storage_key)
      end
    end

  end

end
