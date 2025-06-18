class AddSchoolYearToSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :schedules, :school_year, :string
  end
end
