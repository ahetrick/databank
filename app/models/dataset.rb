class Dataset < ActiveRecord::Base
  has_many :creators, dependent: :destroy

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

    return "#{creator_list}; (#{publication_year}): #{title}; #{publisher}. #{citation_id}"
  end

end
