class CreateCompanyApiAccesses < ActiveRecord::Migration[7.0]
  def change
    create_table :company_api_accesses do |t|
      t.references :api_access, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end
