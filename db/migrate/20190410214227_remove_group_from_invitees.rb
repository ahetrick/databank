class RemoveGroupFromInvitees < ActiveRecord::Migration
  def change
    remove_column :invitees, :group, :string
  end
end
