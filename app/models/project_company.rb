class ProjectCompany < ApplicationRecord
  belongs_to :project
  belongs_to :company

  validates :company_id, uniqueness: {scope: :project_id, message: "Cette entreprise est déjà associée à ce projet"}
end
