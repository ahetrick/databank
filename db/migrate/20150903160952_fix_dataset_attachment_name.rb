class FixDatasetAttachmentName < ActiveRecord::Migration
  def self.up
    rename_column :binaries, :datafile, :attachment
  end

  def self.down
    rename_column :binaries, :attachment, :datafile
  end
end
