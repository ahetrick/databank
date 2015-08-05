class Dataset < ActiveRecord::Base
  has_many :creators, dependent: :destroy

  def creator_list
    creator_list = ""

    if self.creator_ordered_ids && self.creator_ordered_ids.length > 0

      if creator_ordered_ids.respond_to?(split)

        creator_array = self.creator_ordered_ids.split(",")
        creator_array.each_with_index do |creatorID, index|
          if index > 0
            creator_list << "; "
          end
          creator = Creator.find(creatorID)
          creator_list << creator.creator_name.strip
        end

      end

    end

    return creator_list
  end

end
