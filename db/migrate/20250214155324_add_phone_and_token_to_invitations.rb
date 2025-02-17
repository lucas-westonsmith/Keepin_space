class AddPhoneAndTokenToInvitations < ActiveRecord::Migration[7.0]
  def change
    add_column :invitations, :phone, :string
    add_column :invitations, :token, :string, unique: true
  end
end
