class AddParentIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :parent, user: true, null: true, foreign_key: {to_table: :users}
  end
end
