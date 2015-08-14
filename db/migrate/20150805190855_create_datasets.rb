class CreateDatasets < ActiveRecord::Migration
  def change
    create_table :datasets do |t|
      t.string :title
      t.string :identifier
      t.string :publisher
      t.string :publication_year
      t.string :creator_ordered_ids
      t.string :rights
      t.string :key

      t.timestamps null: false
    end
  end
end
