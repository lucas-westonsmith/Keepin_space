class AddSocialLinksToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :secondary_email, :string
    add_column :users, :linkedin, :string
    add_column :users, :facebook, :string
    add_column :users, :instagram, :string
    add_column :users, :twitter, :string
    add_column :users, :tiktok, :string
    add_column :users, :github, :string
  end
end
