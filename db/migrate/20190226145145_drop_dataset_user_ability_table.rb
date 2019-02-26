class DropDatasetUserAbilityTable < ActiveRecord::Migration
  def change
    drop_table :dataset_user_abilities
  end
end
