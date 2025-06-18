class AddSemesterToSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :schedules, :semester, :integer, null: false
  end
end
