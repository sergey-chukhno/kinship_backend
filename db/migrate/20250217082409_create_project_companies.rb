class CreateProjectCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :project_companies do |t|
      t.references :project, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end

    Project.all.each do |project|
      # company_id of project is deleted in the next migration
      next if project.company.blank?

      project_company = ProjectCompany.new(project: project, company: project.company)
      project_company.save!
    end
  end
end
