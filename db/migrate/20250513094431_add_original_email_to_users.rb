class AddOriginalEmailToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :original_email, :string
  end
end
