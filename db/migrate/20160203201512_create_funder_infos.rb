class CreateFunderInfos < ActiveRecord::Migration
  def change
    create_table :funder_infos do |t|
      t.string :code
      t.string :name
      t.string :identifier
      t.integer :display_position
      t.string :identifier_scheme

      t.timestamps null: false
    end
  end
end
