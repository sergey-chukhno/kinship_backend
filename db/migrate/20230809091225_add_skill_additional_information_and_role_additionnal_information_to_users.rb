class AddSkillAdditionalInformationAndRoleAdditionnalInformationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :role_additional_information, :string
    add_column :users, :skill_additional_information, :string
  end
end
