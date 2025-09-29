class SchoolLevel < ApplicationRecord
  include PgSearch::Model

  belongs_to :school

  LEVEL = [:petite_section, :moyenne_section, :grande_section, :cp, :ce1, :ce2, :cm1, :cm2, :sixieme, :cinquieme, :quatrieme, :troisieme, :seconde, :premiere, :terminale, :cap, :bts, :other]
  LEVEL_NAMES = ["1", "A", "2", "B", "3", "C", "4", "D", "5", "E", "6", "F", "7", "G", "8", "H", "9", "I", "10", "J"]
  PRIMARY_SCHOOL_LEVEL = [:petite_section, :moyenne_section, :grande_section, :cp, :ce1, :ce2, :cm1, :cm2]
  SECONDARY_SCHOOL_LEVEL = [:sixieme, :cinquieme, :quatrieme, :troisieme]
  HIGH_SCHOOL_LEVEL = [:seconde, :premiere, :terminale, :cap, :bts]

  has_many :project_school_levels, dependent: :destroy
  has_many :projects, through: :project_school_levels

  has_many :user_school_levels, dependent: :destroy
  has_many :users, through: :user_school_levels

  enum level: LEVEL

  validates :level, :name, presence: true
  validate :validate_level_and_name_uniqueness, if: -> { level.present? && name.present? }
  validate :validate_level_for_primary_school, if: -> { school&.school_type == "primaire" && level.present? }
  validate :validate_level_for_secondary_school, if: -> { school&.school_type == "college" && level.present? }
  validate :validate_level_for_high_school, if: -> { school&.school_type == "lycee" && level.present? }

  pg_search_scope :by_full_name,
    against: [:name, :level],
    associated_against: {
      school: [:name, :city, :zip_code]
    },
    using: {tsearch: {prefix: true}}

  def validate_level_and_name_uniqueness
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
end
