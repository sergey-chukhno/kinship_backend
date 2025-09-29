class AddCompanyIdAndSetSchoolIdNullToTrueToContract < ActiveRecord::Migration[7.0]
  def change
    add_reference :contracts, :company, foreign_key: true
    change_column_null :contracts, :school_id, true
  end
end
