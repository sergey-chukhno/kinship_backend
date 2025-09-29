class AddCompanyReferenceToProject < ActiveRecord::Migration[7.0]
  def change
    add_reference :projects, :company, foreign_key: true
  end
end
