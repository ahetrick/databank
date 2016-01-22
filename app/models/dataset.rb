require 'fileutils'

class Dataset < ActiveRecord::Base

  MIN_FILES = 1
  MAX_FILES = 10000

  has_many :datafiles, dependent: :destroy
  has_many :creators, dependent: :destroy
  accepts_nested_attributes_for :datafiles, :reject_if => :all_blank, allow_destroy: true
  accepts_nested_attributes_for :creators, reject_if: proc { |attributes| (attributes['family_name'].blank?  && attributes['institution_name'].blank? )}, allow_destroy: true

  before_create 'set_key'
  before_save 'set_primary_contact'
  after_save 'remove_invalid_datafiles'
  after_update 'set_has_datacite_changes'

  KEY_LENGTH = 5

  def to_param
    self.key
  end

  # def create_datafile_from_remote(remote_url)
  #   Datafile.create(:remote_binary_url => remote_url, :dataset_id => self.id)
  # end
  # handle_asynchronously :create_datafile_from_remote

  def self.search(search)
    if search

      #start with an empty relation
      search_result = Array.new

      search_terms = search.split(" ")

      search_terms.each do |term|

        #Rails.logger.warn "term class is: #{term.class}"

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


  end # end search

  def to_datacite_xml

    if !self.title || self.creator_list == ""
      raise 'Dataset is not complete; a valid datacite xml document cannot be generated.'
    end

    # creatorArr = self.creator_list.split(";")

    if self.keywords
      keywordArr = self.keywords.split(";")
    end

    contact = Creator.where(dataset_id: self.id, is_contact: true).first
    raise ActiveRecord::RecordNotFound unless contact

    doc = Nokogiri::XML::Document.parse(%Q(<?xml version="1.0"?><resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://datacite.org/schema/kernel-3" xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"></resource>))
    resourceNode = doc.first_element_child

    identifierNode = doc.create_element('identifier')
    identifierNode['identifierType'] = "DOI"
    identifierNode.content = IDB_CONFIG[:ezid_placeholder_identifier]
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

    contributorNode = doc.create_element('contributor')
    contributorNode['contributorType'] = "ContactPerson"
    contributorNode.parent = contributorsNode

    if contact.family_name && contact.given_name
      contributorNameNode = doc.create_element('contributorName')
      contributorNameNode.content = "#{contact.family_name}, #{contact.given_name}"
      contributorNameNode.parent = contributorNode

      if contact.identifier && contact.identifier != ""
        contributorIdentifierNode = doc.create_element('nameIdentifier')
        contributorIdentifierNode["schemeURI"] = "http://orcid.org/"
        contributorIdentifierNode["nameIdentifierScheme"] = "ORCID"
        contributorIdentifierNode.content = "#{contact.identifier}"
        contributorIdentifierNode.parent = contributorNode
      end
    end

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

    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)

  end

  def creator_list
      return_list = ""

      self.creators.each_with_index  do |creator, i|

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
      proposed_key = (36 ** (KEY_LENGTH - 1) +
          rand(36 ** KEY_LENGTH - 36 ** (KEY_LENGTH - 1))).to_s(36)
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

  def remove_invalid_datafiles
    self.datafiles.each do |datafile|
      if (!datafile.medusa_path || datafile.medusa_path == "" ) && (!datafile.binary.path || datafile.binary.path == "")
        datafile.destroy
      end
    end
  end

  def set_has_datacite_changes

  end

end
