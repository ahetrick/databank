class AddDepositorToDatasets < ActiveRecord::Migration
  def change
    add_column :datasets, :depositor_name, :string
    add_column :datasets, :depositor_email, :string
  end
end
