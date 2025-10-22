class SchoolLevel < ApplicationRecord
  include PgSearch::Model

  belongs_to :school, optional: true  # ← Made optional for independent classes

  LEVEL = [:petite_section, :moyenne_section, :grande_section, :cp, :ce1, :ce2, :cm1, :cm2, :sixieme, :cinquieme, :quatrieme, :troisieme, :seconde, :premiere, :terminale, :cap, :bts, :other]
  LEVEL_NAMES = ["1", "A", "2", "B", "3", "C", "4", "D", "5", "E", "6", "F", "7", "G", "8", "H", "9", "I", "10", "J"]
  PRIMARY_SCHOOL_LEVEL = [:petite_section, :moyenne_section, :grande_section, :cp, :ce1, :ce2, :cm1, :cm2]
  SECONDARY_SCHOOL_LEVEL = [:sixieme, :cinquieme, :quatrieme, :troisieme]
  HIGH_SCHOOL_LEVEL = [:seconde, :premiere, :terminale, :cap, :bts]

  # Teacher assignments (NEW - Change #8)
  has_many :teacher_school_levels, dependent: :destroy
  has_many :teachers, through: :teacher_school_levels, source: :user
  
  has_many :project_school_levels, dependent: :destroy
  has_many :projects, through: :project_school_levels

  has_many :user_school_levels, dependent: :destroy
  has_many :users, through: :user_school_levels
  has_many :students, -> { where(role: [:tutor, :children]) }, through: :user_school_levels, source: :user

  enum level: LEVEL

  validates :level, :name, presence: true
  validate :validate_level_and_name_uniqueness, if: -> { level.present? && name.present? }
  validate :validate_level_for_primary_school, if: -> { school&.school_type == "primaire" && level.present? }
  validate :validate_level_for_secondary_school, if: -> { school&.school_type == "college" && level.present? }
  validate :validate_level_for_high_school, if: -> { school&.school_type == "lycee" && level.present? }
  validate :must_have_school_or_creator, on: :update  # NEW - Change #8 (only on update, not create)

  pg_search_scope :by_full_name,
    against: [:name, :level],
    associated_against: {
      school: [:name, :city, :zip_code]
    },
    using: {tsearch: {prefix: true}}
  
  # Scopes (NEW - Change #8)
  scope :independent, -> { where(school_id: nil) }
  scope :school_owned, -> { where.not(school_id: nil) }
  scope :for_teacher, ->(teacher) { 
    joins(:teacher_school_levels).where(teacher_school_levels: {user: teacher}) 
  }

  def validate_level_and_name_uniqueness
    return unless school.present?  # Only validate for school-owned classes
    return unless school.school_levels.where.not(id: id).where(level: level, name: name).any?

    errors.add(:level, "Ce niveau et ce nom existe déjà pour cette école")
    errors.add(:name, "Ce niveau et ce nom existe déjà pour cette école")
  end

  def validate_level_for_primary_school
    return if school.school_type == "primaire" && PRIMARY_SCHOOL_LEVEL.include?(level.to_sym)

    errors.add(:level, "Ce niveau n'est pas un niveau de primaire")
  end

  def validate_level_for_secondary_school
    return if school.school_type == "college" && SECONDARY_SCHOOL_LEVEL.include?(level.to_sym)

    errors.add(:level, "Ce niveau n'est pas un niveau de collège")
  end

  def validate_level_for_high_school
    return if school.school_type == "lycee" && HIGH_SCHOOL_LEVEL.include?(level.to_sym)

    errors.add(:level, "Ce niveau n'est pas un niveau de lycée")
  end

  def full_name
    "#{I18n.t("activerecord.attributes.school_level.levels.#{level}")} #{name} - #{school.full_name}"
  end

  def full_name_without_school
    "#{I18n.t("activerecord.attributes.school_level.levels.#{level}")} #{name}"
  end

  def level_name
    I18n.t("activerecord.attributes.school_level.levels.#{level}")
  end
  
  # ========================================
  # TEACHER ASSIGNMENT METHODS (Change #8)
  # ========================================
  
  # Status checks
  def independent?
    school_id.nil?
  end
  
  def school_owned?
    school_id.present?
  end
  
  # Creator tracking
  def creator
    teacher_school_levels.find_by(is_creator: true)&.user
  end
  
  def created_by?(teacher)
    teacher_school_levels.exists?(user: teacher, is_creator: true)
  end
  
  # Teacher management
  def assign_teacher(teacher, is_creator: false)
    teacher_school_levels.create!(
      user: teacher,
      is_creator: is_creator,
      assigned_at: Time.current
    )
  end
  
  def remove_teacher(teacher)
    teacher_school_levels.find_by(user: teacher)&.destroy
  end
  
  def teacher_assigned?(teacher)
    teachers.include?(teacher)
  end
  
  # Transfer ownership
  def transfer_to_school(school, transferred_by:)
    return false if self.school.present?  # Already owned by a school
    return false unless transferred_by.user_schools.exists?(school: school, status: :confirmed)
    
    transaction do
      update!(school: school)
      
      # Notify school admins
      school.user_schools.where(role: [:admin, :superadmin], status: :confirmed).each do |user_school|
        # TODO: Send notification email when mailer is created
        # SchoolLevelMailer.notify_transfer_to_school(self, user_school.user).deliver_later
      end
      
      true
    end
  end
  
  private
  
  def must_have_school_or_creator
    if school_id.nil? && !teacher_school_levels.exists?(is_creator: true)
      errors.add(:base, "La classe doit appartenir à une école ou avoir un enseignant créateur")
    end
  end
end
