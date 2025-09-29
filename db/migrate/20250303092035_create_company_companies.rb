class CreateCompanyCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :company_companies do |t|
      t.integer :status
      t.references :company_sponsor, null: false, foreign_key: {to_table: :companies}
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end
