class Deckfile < ActiveRecord::Base
  belongs_to :dataset
  audited associated_with: :dataset

  before_destroy :delete_file

  def delete_file
    if File.exists?(self.path)
      File.delete(self.path)
    end
    #remove directory if empty

  end

end
