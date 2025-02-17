class AddEventIdToNotes < ActiveRecord::Migration[7.1]
  def change
    add_reference :notes, :event, foreign_key: true
  end
end
