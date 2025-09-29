class CreateCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :zip_code, null: false
      t.string :city, null: false
      t.string :referent_phone_number, null: false
      t.string :description, null: false
      t.integer :status, null: false, default: 0
      t.references :company_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
