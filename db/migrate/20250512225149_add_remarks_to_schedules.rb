class AddRemarksToSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :schedules, :remarks, :integer, null: true
  end
end
