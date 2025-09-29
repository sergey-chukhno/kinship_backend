class EditStartDateNullToFalseToContract < ActiveRecord::Migration[7.0]
  def change
    change_column_null :contracts, :start_date, false
  end
end
