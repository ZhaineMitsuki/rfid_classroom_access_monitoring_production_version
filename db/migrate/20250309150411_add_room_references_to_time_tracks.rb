class AddRoomReferencesToTimeTracks < ActiveRecord::Migration[7.0]
  def change
    add_reference :time_tracks, :room
  end
end
