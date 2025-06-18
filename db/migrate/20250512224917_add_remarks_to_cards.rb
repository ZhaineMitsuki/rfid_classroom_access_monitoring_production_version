class AddRemarksToCards < ActiveRecord::Migration[7.0]
  def change
    add_column :cards, :remarks, :integer, null: true
  end
end
