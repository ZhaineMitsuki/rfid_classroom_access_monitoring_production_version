class AddOriginalRoomNumberToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :original_room_number, :integer
  end
end
