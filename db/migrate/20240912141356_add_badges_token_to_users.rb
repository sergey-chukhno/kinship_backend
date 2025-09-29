class AddBadgesTokenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :badges_token, :string
  end
end
