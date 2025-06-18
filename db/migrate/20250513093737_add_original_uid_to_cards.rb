class AddOriginalUidToCards < ActiveRecord::Migration[7.0]
  def change
    add_column :cards, :original_uid, :string
  end
end
