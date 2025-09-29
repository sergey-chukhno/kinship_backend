class AddCertifyToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :certify, :boolean, default: false
  end
end
