class CreatePollOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :poll_options do |t|
      t.references :poll, null: false, foreign_key: true
      t.string :content
      t.integer :votes_count, default: 0
      t.timestamps
    end
  end
end
