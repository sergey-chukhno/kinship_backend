# School serializer for API responses
# Integrates with logos (Change #2), partnerships (Change #5), and branches (Change #7)
class SchoolSerializer < ActiveModel::Serializer
  attributes :id, :name, :city, :zip_code, :full_name, :school_type,
             :status, :logo_url, :has_active_contract,
             :teachers_count, :students_count, :levels_count,
             :projects_count, :partnerships_count,
             :is_branch, :has_parent, :has_branches, :created_at
  
  # Associations (limited to prevent circular references)
  has_many :school_levels, serializer: SchoolLevelSerializer
  # Avoid circular references:
  # has_many :users - Would cause School → User → School loop
  # has_many :partnerships - Would cause School → Partnership → School loop
  # Use counts and IDs instead, fetch separately when needed
  
  # Branch relationships (Change #7: Branch System)
  # Limited to prevent circular references (depth limit = 2)
  attribute :parent_school
  attribute :branch_schools
  
  # Computed attributes
  
  # Logo URL from Change #2: School logos
  def logo_url
    return nil unless object.logo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(object.logo, only_path: false)
  end
  
  def has_active_contract
    object.active_contract?
  end
  
  # Branch flags from Change #7
  def is_branch
    object.parent_school_id.present?
  end
  
  def has_parent
    object.parent_school_id.present?
  end
  
  def has_branches
    object.branch_schools.any?
  end
  
  # Parent school (simple object to prevent deep nesting)
  def parent_school
    return nil unless object.parent_school
    
    {
      id: object.parent_school.id,
      name: object.parent_school.name,
      city: object.parent_school.city,
      school_type: object.parent_school.school_type,
      logo_url: object.parent_school.logo.attached? ? 
        Rails.application.routes.url_helpers.rails_blob_url(object.parent_school.logo, only_path: false) : nil
    }
  end
  
  # Branch schools (simple objects to prevent deep nesting)
  def branch_schools
    object.branch_schools.map do |child|
      {
        id: child.id,
        name: child.name,
        city: child.city,
        school_type: child.school_type,
        status: child.status,
        logo_url: child.logo.attached? ? 
          Rails.application.routes.url_helpers.rails_blob_url(child.logo, only_path: false) : nil
      }
    end
  end
  
  # Counts
  def teachers_count
    object.users.where(role: :teacher).count
  end
  
  def students_count
    object.users.where(role: [:tutor, :children]).count
  end
  
  def levels_count
    object.school_levels.count
  end
  
  def projects_count
    # Projects are linked via school_levels -> project_school_levels
    Project.joins(project_school_levels: :school_level)
           .where(school_levels: { school_id: object.id })
           .distinct
           .count
  end
  
  def partnerships_count
    object.active_partnerships.count
  end
end

