class AddTimeInAndTimeOutToTimeTracks < ActiveRecord::Migration[7.0]
  def change
    add_column :time_tracks, :time_in, :string, default: nil
    add_column :time_tracks, :time_out, :string, default: nil
  end
end
