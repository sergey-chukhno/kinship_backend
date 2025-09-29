class AddExpendSkillToSchoolToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :expend_skill_to_school, :boolean, default: false
  end
end
