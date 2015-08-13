class RenameRightsColumn < ActiveRecord::Migration
  def change
    rename_column :datasets, :rights, :license
  end
end
