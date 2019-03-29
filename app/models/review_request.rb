class ReviewRequest < ActiveRecord::Base
  def dataset
    Dataset.find_by_key(self.dataset_key)
  end
end
