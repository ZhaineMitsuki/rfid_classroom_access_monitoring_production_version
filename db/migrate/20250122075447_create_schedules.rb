class CreateSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :schedules do |t|
      t.references :user
      t.integer :description
      t.string :subject
      t.integer :day
      t.datetime :start_time
      t.datetime :end_time
      t.timestamps
    end
  end
end
