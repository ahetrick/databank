class CreateCreators < ActiveRecord::Migration
  def change
    create_table :creators do |t|
      t.string :creator_name
      t.string :identifier
      t.integer :dataset_id

      t.timestamps null: false
    end
  end
end
