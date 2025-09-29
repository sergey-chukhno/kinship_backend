class AddIsBannedToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :is_banned, :boolean, default: false
  end
end
