class AddDeleteTokenToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :delete_token, :string
    add_column :users, :delete_token_sent_at, :datetime
  end
end
