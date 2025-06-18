class AddRemarksToTimeTracks < ActiveRecord::Migration[7.0]
  def change
    add_column :time_tracks, :remarks, :integer
  end
end
