class CreateSchoolCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :school_companies do |t|
      t.references :school, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
