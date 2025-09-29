class AddSiretNumberSkillAdditionnalInformationAndEmailToCompany < ActiveRecord::Migration[7.0]
  def change
    add_column :companies, :siret_number, :string
    add_column :companies, :skill_additional_information, :string
    add_column :companies, :email, :string
  end
end
