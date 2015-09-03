class Dataset < ActiveRecord::Base

  has_many :creators, dependent: :destroy
  has_many :binaries, dependent: :destroy
  accepts_nested_attributes_for :binaries, :reject_if => :all_blank, allow_destroy: true

  before_create 'set_key'
  after_save 'save_to_repo'
  before_destroy 'delete_repository_entity'


  validates :depositor_email, presence: {:message => "Deposit Agreement required to deposit dataset (see link next to Update Dataset button in the bottom right of form)."}
  validates :title, presence: true

  KEY_LENGTH = 5

  def creator_list
    creator_text
  end

  def plain_text_citation

    citation_id = (identifier && !identifier.empty?) ? "http://dx.doi.org/#{identifier}" : ""

    return "#{creator_list} (#{publication_year}): #{title}. #{publisher}. #{citation_id}"
  end

  def collection
    if !self.key || self.key.empty?
      nil
    else
      collection = Repository::Collection.find_by_key(self.key)
      raise ActiveRecord::RecordNotFound unless collection
    end

  end

  def datafiles
    if !self.key || self.key.empty?
      nil
    else
      col = Repository::Collection.find_by_key(self.key)
      raise ActiveRecord::RecordNotFound unless col
      Repository::Item.where(Solr::Fields::COLLECTION => col.id)
    end
  end

  def save_to_repo
    collection = Repository::Collection.find_by_key(self.key)
    if collection.nil?
      collection = Repository::Collection.new :parent_url => IDB_CONFIG[:fedora_url]
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
    Solr::Solr.client.commit

    binaries.each do |binary|

      # make item
      item = Repository::Item.new(
          collection: collection,
          parent_url: collection.id,
          published: true,
          description: binary.description)
      item.save!
      Rails.logger.debug "Created #{item.id}"

      Solr::Solr.client.commit
      Rails.logger.debug "Committed #{item.id}"

      path = binary.datafile.current_path
      if File.exists?(path)
        bs = Repository::Bytestream.new(
            parent_url: item.id,
            type: Repository::Bytestream::Type::MASTER,
            item: item,
            upload_pathname: path)

        bs.media_type = binary.datafile.file.content_type
        bs.save!
        Rails.logger.debug "Created master bytestream"
        Solr::Solr.client.commit

        binary.destroy
      else
        Rails.logger.debug "Did not find path #{path}"
      end

    end

  end

  def delete_repository_entity
    collection = Repository::Collection.find_by_key(self.key)
    if !collection.nil?
      datafiles.each do |datafile|
        datafile.destroy
        Solr::Solr.client.commit
      end
      collection.destroy
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
