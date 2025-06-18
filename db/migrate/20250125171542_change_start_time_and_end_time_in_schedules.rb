class ChangeStartTimeAndEndTimeInSchedules < ActiveRecord::Migration[7.0]
  def change
    change_column :schedules, :start_time, :time
    change_column :schedules, :end_time, :time
  end
end
