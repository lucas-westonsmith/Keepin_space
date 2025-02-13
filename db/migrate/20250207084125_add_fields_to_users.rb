class AddFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone_number, :string
    add_column :users, :bio, :text
    add_column :users, :hobbies, :text
    add_column :users, :avatar, :string
    add_column :users, :role, :integer, default: 1, null: false  # 1 = member par défaut
  end
end
