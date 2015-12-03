require 'fileutils'

class Dataset < ActiveRecord::Base

  MIN_FILES = 1
  MAX_FILES = 10000

  has_many :datafiles, dependent: :destroy
  accepts_nested_attributes_for :datafiles, :reject_if => :all_blank, allow_destroy: true

  before_create 'set_key'

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

    if creator_list == ""
      creator_list = "[Creator List]"
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

end
