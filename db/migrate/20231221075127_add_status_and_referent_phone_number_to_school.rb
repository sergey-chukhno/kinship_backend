class AddStatusAndReferentPhoneNumberToSchool < ActiveRecord::Migration[7.0]
  def up
    add_column :schools, :status, :integer, default: 0, null: false
    add_column :schools, :referent_phone_number, :string
    School.update_all(status: 1)
  end

  def down
    remove_column :schools, :status
    remove_column :schools, :referent_phone_number
  end
end
