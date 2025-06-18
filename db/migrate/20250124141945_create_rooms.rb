class CreateRooms < ActiveRecord::Migration[7.0]
  def change
    create_table :rooms do |t|
      t.integer :room_number
      t.integer :room_status, default: 1
      t.timestamps
    end
  end
end
