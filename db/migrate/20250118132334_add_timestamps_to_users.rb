class AddTimestampsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :users, null: true # Correct table name

    # Backfill existing records with default values
    long_ago = DateTime.new(2000, 1, 1)
    User.update_all(created_at: long_ago, updated_at: long_ago)

    # Change the columns to not allow null values
    change_column_null :users, :created_at, false
    change_column_null :users, :updated_at, false
  end
end
