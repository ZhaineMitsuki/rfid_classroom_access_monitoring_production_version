class AddYearLevelToSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :schedules, :year_level, :integer
  end
end
