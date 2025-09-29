class CreateUserCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :user_companies do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.boolean :admin, null: false, default: false
      t.boolean :owner, null: false, default: false

      t.timestamps
    end
  end
end
