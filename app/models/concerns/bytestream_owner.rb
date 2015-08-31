module BytestreamOwner

  ##
  # Returns the path at which an item's image is expected to reside.
  #
  # @param size [Integer] One of the sizes in `IMAGE_DERIVATIVES`
  # @param shape [String] One of the `Repository::Bytestream::Shape` constants
  # @return [Repository::Bytestream, nil]
  #
  def derivative_image(size, shape = Repository::Bytestream::Shape::ORIGINAL)
    q = "("\
      "(#{Solr::Fields::WIDTH}:#{size} AND #{Solr::Fields::HEIGHT}:[* TO #{size}]) "\
      "OR (#{Solr::Fields::HEIGHT}:#{size} AND #{Solr::Fields::WIDTH}:[* TO #{size}])"\
      ") "\
      "AND #{Solr::Fields::BYTESTREAM_SHAPE}:\"#{shape}\""
    self.bytestreams.where(q).limit(1).first
  end

  def is_audio?
    bs = self.master_bytestream
    bs and bs.is_audio?
  end

  def is_image?
    bs = self.master_bytestream
    bs and bs.is_image?
  end

  def is_pdf?
    bs = self.master_bytestream
    bs and bs.is_pdf?
  end

  def is_text?
    bs = self.master_bytestream
    bs and bs.is_text?
  end

  def is_video?
    bs = self.master_bytestream
    bs and bs.is_video?
  end

  ##
  # @return [Repository::Bytestream]
  #
  def master_bytestream
    unless @master_bytestream
      @master_bytestream = self.bytestreams.facet(false).
          where(Solr::Fields::BYTESTREAM_TYPE =>
                    Repository::Bytestream::Type::MASTER).first
    end
    @master_bytestream
  end

  def bytestreams
    Repository::Bytestream.where(Solr::Fields::ITEM => self.id)
  end

  ##
  # @return [Repository::Bytestream, nil] Nil if the instance is not an image.
  #
  def master_image
    self.is_image? ? self.master_bytestream : nil
  end

  ##
  # @return [String]
  #
  def media_type
    bs = self.master_bytestream
    bs ? bs.media_type : nil
  end

end
