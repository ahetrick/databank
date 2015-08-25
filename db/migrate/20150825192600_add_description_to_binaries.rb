class AddDescriptionToBinaries < ActiveRecord::Migration
  def change
    add_column :binaries, :description, :string
  end
end
