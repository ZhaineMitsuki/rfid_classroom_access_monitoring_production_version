class CreateTimeTrack < ActiveRecord::Migration[7.0]
  def change
    create_table :time_tracks do |t|
      t.references :user
      t.integer :status, default: 0
      t.timestamps
    end
  end
end
