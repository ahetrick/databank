class CreateBinaries < ActiveRecord::Migration
  def change
    create_table :binaries do |t|
      t.string :attachment
      t.string :description
      t.integer :dataset_id
      t.timestamps null: false
    end
  end
end
