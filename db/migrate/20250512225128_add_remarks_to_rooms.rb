class AddRemarksToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :remarks, :integer, null: true
  end
end
