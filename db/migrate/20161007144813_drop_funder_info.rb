class DropFunderInfo < ActiveRecord::Migration
  def change
    drop_table :funder_infos
  end
end
