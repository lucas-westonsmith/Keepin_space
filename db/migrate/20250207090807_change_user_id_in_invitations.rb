class ChangeUserIdInInvitations < ActiveRecord::Migration[7.0]
  def change
    change_column_null :invitations, :user_id, true
  end
end
