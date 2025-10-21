# SchoolLevel serializer for API responses
# Integrates with teacher-class assignments (Change #8)
class SchoolLevelSerializer < ActiveModel::Serializer
  attributes :id, :name, :level, :school_id, :created_at,
             :is_independent, :is_school_owned, :is_school_created,
             :students_count, :teachers_count
  
  # Associations
  # Avoid circular reference (SchoolLevel → School → SchoolLevel)
  # belongs_to :school - Omitted, use school_id instead
  has_many :teachers, serializer: UserSerializer
  has_many :students, serializer: UserSerializer
  
  # Creator information (Change #8: Teacher-class assignments)
  attribute :creator
  
  # Computed attributes
  
  # From Change #8: Teacher-class assignment system
  def is_independent
    object.independent?
  end
  
  def is_school_owned
    object.school_owned?
  end
  
  def is_school_created
    # Class created by school, not by teacher
    object.school_id.present? && !object.teacher_school_levels.exists?(is_creator: true)
  end
  
  # Creator of the class (teacher who created it)
  def creator
    return nil unless object.creator
    
    {
      id: object.creator.id,
      first_name: object.creator.first_name,
      last_name: object.creator.last_name,
      full_name: object.creator.full_name,
      email: object.creator.email
    }
  end
  
  def students_count
    object.students.count
  end
  
  def teachers_count
    object.teachers.count
  end
end

