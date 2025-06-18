class AddOriginalSchoolYearToSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :schedules, :original_school_year, :string
  end
end
