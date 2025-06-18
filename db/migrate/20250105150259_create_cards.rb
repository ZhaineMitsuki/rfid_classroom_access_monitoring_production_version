class CreateCards < ActiveRecord::Migration[7.0]
  def change
    create_table :cards do |t|
      t.string :uid
      t.integer :status, default: 0
      t.references :user
      t.timestamps
    end
  end
end
