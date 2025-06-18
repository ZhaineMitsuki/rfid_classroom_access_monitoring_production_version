class AddUidTypeForCards < ActiveRecord::Migration[7.0]
  def change
    add_column :cards, :uid_type, :integer, default: 0
  end
end
