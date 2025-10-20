class TeacherSchoolLevel < ApplicationRecord
  belongs_to :user
  belongs_to :school_level
  
  # Validations
  validates :user_id, uniqueness: {
    scope: :school_level_id, 
    message: "est déjà assigné(e) à cette classe"
  }
  validate :user_must_be_teacher
  
  # Scopes
  scope :creators, -> { where(is_creator: true) }
  scope :assigned, -> { where(is_creator: false) }
  
  # Callbacks
  before_validation :set_assigned_at, on: :create
  
  private
  
  def user_must_be_teacher
    unless user&.teacher?
      errors.add(:user, "doit être un enseignant")
    end
  end
  
  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
