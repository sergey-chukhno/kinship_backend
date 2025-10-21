# Company serializer for API responses
# Integrates with logos (Change #2), partnerships (Change #5), and branches (Change #7)
class CompanySerializer < ActiveModel::Serializer
  attributes :id, :name, :city, :zip_code, :full_name, :description,
             :email, :website, :status, :take_trainee, :propose_workshop,
             :propose_summer_job, :logo_url, :has_active_contract,
             :members_count, :projects_count, :partnerships_count,
             :is_branch, :has_parent, :has_branches, :created_at
  
  # Associations (limited to prevent circular references)
  belongs_to :company_type, serializer: CompanyTypeSerializer
  has_many :skills, serializer: SkillSerializer
  has_many :sub_skills, serializer: SubSkillSerializer
  # Avoid circular references:
  # has_many :users - Would cause Company → User → Company loop
  # has_many :projects - Would cause Company → Project → Company loop
  # has_many :partnerships - Would cause Company → Partnership → Company loop
  # Use counts and IDs instead, fetch separately when needed
  
  # Branch relationships (Change #7: Branch System)
  # Limited to prevent circular references (depth limit = 2)
  attribute :parent_company
  attribute :branch_companies
  
  # Computed attributes
  
  # Logo URL from Change #2: Company logos
  def logo_url
    return nil unless object.logo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(object.logo, only_path: false)
  end
  
  def has_active_contract
    object.active_contract?
  end
  
  # Branch flags from Change #7
  def is_branch
    object.parent_company_id.present?
  end
  
  def has_parent
    object.parent_company_id.present?
  end
  
  def has_branches
    object.branch_companies.any?
  end
  
  # Parent company (simple object to prevent deep nesting)
  def parent_company
    return nil unless object.parent_company
    
    {
      id: object.parent_company.id,
      name: object.parent_company.name,
      city: object.parent_company.city,
      logo_url: object.parent_company.logo.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(object.parent_company.logo, only_path: false) : nil
    }
  end
  
  # Branch companies (simple objects to prevent deep nesting)
  def branch_companies
    object.branch_companies.map do |child|
      {
        id: child.id,
        name: child.name,
        city: child.city,
        status: child.status,
        logo_url: child.logo.attached? ? 
          Rails.application.routes.url_helpers.rails_blob_url(child.logo, only_path: false) : nil
      }
    end
  end
  
  # Counts
  def members_count
    object.users.count
  end
  
  def projects_count
    object.projects.count
  end
  
  def partnerships_count
    object.active_partnerships.count
  end
end

