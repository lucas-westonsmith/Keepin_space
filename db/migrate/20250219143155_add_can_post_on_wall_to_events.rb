class AddCanPostOnWallToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :can_post_on_wall, :boolean, default: false
  end
end
