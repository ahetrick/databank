require 'fileutils'

class Dataset < ActiveRecord::Base

  MIN_FILES = 1
  MAX_FILES = 10000


  has_many :binaries, dependent: :destroy
  accepts_nested_attributes_for :binaries, :reject_if => :all_blank, allow_destroy: true

  before_create 'set_key'
  after_save 'save_to_repo'
  before_destroy 'delete_repository_entity'

  KEY_LENGTH = 5

  def to_param
    self.key
  end

  def self.search(search)
    if search
      lower_search = search.downcase
      where('lower(title) LIKE :search OR lower(keywords) LIKE :search OR lower(creator_text) LIKE :search OR lower(identifier) LIKE :search OR lower(description) LIKE :search', search: "%#{lower_search}%")
    else
      Dataset.all
    end
  end

  def to_datacite_xml

    if !self.title || !self.creator_text
      raise 'Dataset is not complete; a valid datacite xml document cannot be generated.'
    end

    creatorArr = self.creator_text.split(";")

    if self.keywords
      keywordArr = self.keywords.split(";")
    end

    doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
    resourceNode = doc.first_element_child

    identifierNode = doc.create_element('identifier')
    identifierNode['identifierType'] = "DOI"
    identifierNode.content = IDB_CONFIG[:ezid_placeholder_identifier]
    identifierNode.parent = resourceNode

    creatorsNode = doc.create_element('creators')
    creatorsNode.parent = resourceNode

    creatorArr.each do |creator|
      creatorNode = doc.create_element('creator')
      creatorNode.parent = creatorsNode

      creatorNameNode = doc.create_element('creatorName')
      creatorNameNode.content = creator.strip
      creatorNameNode.parent = creatorNode

    end

    titlesNode = doc.create_element('titles')
    titlesNode.parent = resourceNode

    titleNode = doc.create_element('title')
    titleNode.content = self.title || "Dataset Title"
    titleNode.parent = titlesNode

    publisherNode = doc.create_element('publisher')
    publisherNode.content = self.publisher || "University of Illinois at Urbana-Champaign"
    publisherNode.parent = resourceNode

    publicationYearNode = doc.create_element('publicationYear')
    publicationYearNode.content = self.publication_year || "2015"
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

    languageNode = doc.create_element('language')
    languageNode.content = "en-us"
    languageNode.parent = resourceNode

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

    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)

  end

  def creator_list
    creator_text
  end

  def plain_text_citation

    citation_id = (identifier && !identifier.empty?) ? "http://dx.doi.org/#{identifier}" : ""

    return "#{creator_list} (#{publication_year}): #{title}. #{publisher}. #{citation_id}"
  end

  def repo_dataset
    if !self.key || self.key.empty?
      nil
    else
      repo_dataset = Repository::RepoDataset.find_by_key(self.key)
      raise ActiveRecord::RecordNotFound unless repo_dataset
    end

  end

  def datafiles
    if !self.key || self.key.empty?
      nil
    else
      repo_dataset = Repository::RepoDataset.find_by_key(self.key)
      raise ActiveRecord::RecordNotFound unless repo_dataset
      Repository::Datafile.where(Solr::Fields::DATASET => repo_dataset.id).limit(MAX_FILES)
    end
  end

  def save_to_repo
    repo_dataset = Repository::RepoDataset.find_by_key(self.key)
    if repo_dataset.nil?
      repo_dataset = Repository::RepoDataset.new :parent_url => IDB_CONFIG[:fedora_url]
    end
    repo_dataset.key = self.key
    repo_dataset.published = self.complete?
    repo_dataset.title = self.title
    repo_dataset.creator_list = self.creator_list
    repo_dataset.description = self.description
    repo_dataset.identifier = self.identifier
    repo_dataset.license = self.license
    repo_dataset.publication_year = self.publication_year
    repo_dataset.publisher = self.publisher
    repo_dataset.keywords = self.keywords
    repo_dataset.save!
    Solr::Solr.client.commit

    binaries.each do |binary|
      unless binary.attachment.nil? || binary.attachment.current_path.nil?
         begin
          # make datafile
          datafile = Repository::Datafile.new(
              repo_dataset: repo_dataset,
              parent_url: repo_dataset.id,
              published: true,
              description: binary.description)
          datafile.save!

          Solr::Solr.client.commit

          path = binary.attachment.current_path
          if File.exists?(path)
            bs = Repository::Bytestream.new(
                parent_url: datafile.id,
                type: Repository::Bytestream::Type::MASTER,
                datafile: datafile,
                upload_pathname: path)

            bs.media_type = binary.attachment.file.content_type
            bs.save!
            Solr::Solr.client.commit

            binary.destroy

          else
            Rails.logger.debug "Did not find path #{path}"
          end

         rescue Exception => ex

           datafile.destroy if datafile
           bs.destroy if bs
           binary.destroy if binary
           raise ex

         end #end make datafile/bytestream transaction

      end
    end
    #clean upload directory
    FileUtils.rm_rf('public/uploads/tmp')
    FileUtils.rm_rf('public/uploads/binary')
  end

  def delete_repository_entity
    repo_dataset = Repository::RepoDataset.find_by_key(self.key)
    if !repo_dataset.nil?
      datafiles.each do |datafile|
        datafile.destroy
        Solr::Solr.client.commit
      end
      repo_dataset.destroy
    end
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
      proposed_key = (36 ** (KEY_LENGTH - 1) +
          rand(36 ** KEY_LENGTH - 36 ** (KEY_LENGTH - 1))).to_s(36)
      break unless self.class.find_by_key(proposed_key)
    end
    proposed_key
  end

end
