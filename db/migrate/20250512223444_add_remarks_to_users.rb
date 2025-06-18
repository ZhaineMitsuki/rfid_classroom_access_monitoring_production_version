class AddRemarksToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :remarks, :integer, null: true
  end
end
