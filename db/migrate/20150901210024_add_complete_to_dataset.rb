class AddCompleteToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :complete, :boolean, :default => false
  end
end
