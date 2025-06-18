class FixPostgresqlCompatibility < ActiveRecord::Migration[7.0]
  def up
    # Remove MySQL-specific default values for time_in and time_out columns
    change_column_default :time_tracks, :time_in, nil
    change_column_default :time_tracks, :time_out, nil
  end

  def down
    # Revert back to MySQL defaults (this won't work in PostgreSQL, but for rollback completeness)
    change_column_default :time_tracks, :time_in, -> { "time_format(current_timestamp(),'%I:%M %p')" }
    change_column_default :time_tracks, :time_out, -> { "time_format(current_timestamp(),'%I:%M %p')" }
  end
end
