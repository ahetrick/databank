class CreateDeckfiles < ActiveRecord::Migration
  def change
    create_table :deckfiles do |t|
      t.string :disposition, default: "ingest"
      t.boolean :remove, default: false
      t.string :path
      t.integer :dataset_id

      t.timestamps null: false
    end
  end
end
