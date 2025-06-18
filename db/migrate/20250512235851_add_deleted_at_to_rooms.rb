class AddDeletedAtToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :deleted_at, :datetime
  end
end
