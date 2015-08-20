class Dataset < ActiveRecord::Base
  has_many :creators, dependent: :destroy

  after_save 'save_to_repo'
  before_destroy 'delete_repository_entity'
  before_create 'set_key'

  KEY_LENGTH = 5

  def creator_list
    creator_list = ""

    if creator_ordered_ids && !creator_ordered_ids.empty? && creator_ordered_ids.respond_to?(:split)
      creator_array = creator_ordered_ids.split(",")
      creator_array.each_with_index do |creatorID, index|
        if index > 0
          creator_list << "; "
        end
        creator = Creator.find(creatorID)
        creator_list << creator.creator_name.strip
      end
    end

    return creator_list
  end

  def plain_text_citation

    citation_id = (identifier && !identifier.empty?) ? "http://dx.doi.org/#{identifier}" : ""

    return "#{creator_list} (#{publication_year}): #{title}. #{publisher}. #{citation_id}"
  end

  def collection
    collection = Repository::Collection.find_by_key(self.key)
  end

  def datafiles
    Repository::Item.where(Solr::Fields::COLLECTION => collection.repository_url)
  end

  def save_to_repo
    collection = Repository::Collection.find_by_key(self.key)
    if collection.nil?
      collection = Repository::Collection.new :parent_url => Databank::Application.databank_config[:fedora_url]
    end
    collection.key = self.key
    collection.published = true
    collection.title = self.title
    collection.creator_list = self.creator_list
    collection.description = self.description
    collection.identifier = self.identifier
    collection.license = self.license
    collection.publication_year = self.publication_year
    collection.publisher = self.publisher
    collection.save!

  end

  def delete_repository_entity
    collection = Repository::Collection.find_by_key(self.key)
    if !collection.nil?
      datafiles.each do |datafile|
        datafile.destroy
      end
      collection.destroy
    end
  end

  def set_key
    self.key = generate_key
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
