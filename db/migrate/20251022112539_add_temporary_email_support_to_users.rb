class AddTemporaryEmailSupportToUsers < ActiveRecord::Migration[7.1]
  def change
    # Support for students created without email
    add_column :users, :has_temporary_email, :boolean, default: false, null: false
    add_column :users, :claim_token, :string
    
    add_index :users, :claim_token, unique: true
    add_index :users, :has_temporary_email
  end
end
