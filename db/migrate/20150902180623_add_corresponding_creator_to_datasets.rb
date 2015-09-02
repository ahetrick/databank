class AddCorrespondingCreatorToDatasets < ActiveRecord::Migration
  def change
    add_column :datasets, :corresponding_creator_name, :string
    add_column :datasets, :corresponding_creator_email, :string
  end
end
