class AddCardIdToTimeTracks < ActiveRecord::Migration[7.0]
  def change
    add_column :time_tracks, :card_id, :integer
    add_index :time_tracks, :card_id
  end
end
