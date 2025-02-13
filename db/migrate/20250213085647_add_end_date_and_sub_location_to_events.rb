class AddEndDateAndSubLocationToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :end_date, :datetime
    add_column :events, :sub_location, :string
  end
end
