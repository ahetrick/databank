class AddCreatorTextToDatasets < ActiveRecord::Migration
  def change
    add_column :datasets, :creator_text, :string
  end
end
