class ChangeVisibilityInEvents < ActiveRecord::Migration[7.0]
  def change
    change_column_default :events, :visibility, from: 0, to: nil
  end
end
