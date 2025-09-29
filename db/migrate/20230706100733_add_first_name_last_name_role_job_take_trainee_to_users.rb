class AddFirstNameLastNameRoleJobTakeTraineeToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :role, :integer
    add_column :users, :job, :string, default: "Professeur"
    add_column :users, :take_trainee, :boolean, default: false
  end
end
