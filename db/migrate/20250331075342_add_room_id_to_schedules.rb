class AddRoomIdToSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :schedules, :room_id, :integer
  end
end
