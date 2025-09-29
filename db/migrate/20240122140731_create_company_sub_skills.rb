class CreateCompanySubSkills < ActiveRecord::Migration[7.0]
  def change
    create_table :company_sub_skills do |t|
      t.references :company, null: false, foreign_key: true
      t.references :sub_skill, null: false, foreign_key: true

      t.timestamps
    end
  end
end
