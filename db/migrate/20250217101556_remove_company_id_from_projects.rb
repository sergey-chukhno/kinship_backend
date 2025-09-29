class RemoveCompanyIdFromProjects < ActiveRecord::Migration[7.0]
  def change
    remove_column :projects, :company_id, :bigint
  end
end
