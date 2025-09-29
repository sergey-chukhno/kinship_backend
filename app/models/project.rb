class Project < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :project_companies, dependent: :destroy
  has_many :companies, through: :project_companies

  has_many :project_tags, dependent: :destroy
  has_many :tags, through: :project_tags
  has_many :project_skills, dependent: :destroy
  has_many :skills, through: :project_skills
  has_many :keywords, dependent: :destroy
  has_many :project_school_levels, dependent: :destroy
  has_many :school_levels, through: :project_school_levels
  has_many :users, through: :school_levels
  has_many :schools, through: :school_levels
  has_many :links, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :team_members, through: :teams
  has_many :project_members, dependent: :destroy
  has_many :user_badges, -> { where(status: :approved) }, dependent: :destroy
  has_one_attached :main_picture
  has_many_attached :pictures
  has_many_attached :documents

  accepts_nested_attributes_for :project_tags, allow_destroy: true
  accepts_nested_attributes_for :links, allow_destroy: true
  accepts_nested_attributes_for :keywords, allow_destroy: true
  accepts_nested_attributes_for :project_skills, allow_destroy: true
  accepts_nested_attributes_for :project_school_levels, allow_destroy: true
  accepts_nested_attributes_for :project_companies, allow_destroy: true
  accepts_nested_attributes_for :teams, allow_destroy: true

  enum :status, [:coming, :in_progress, :ended], default: :coming

  validates :title, :description, :start_date, :end_date, :owner, :status, presence: true
  validate :start_date_before_end_date, if: -> { start_date.present? && end_date.present? }
  validate :school_levels_or_company_presence, unless: -> { owner&.admin? }

  scope :kinship, -> {
    Project
      .where(project_school_levels: {id: nil})
  }

  scope :default_project, ->(current_user) {
    includes(:team_members, :project_members, :project_school_levels, :schools, :school_levels, :main_picture_attachment)
      .all
  }

  scope :search, ->(query) {
    query_words = query.split(" ")
    where(
      query_words.map { |word| "projects.title ILIKE ? OR projects.description ILIKE ?" }.join(" OR "),
      *query_words.map { |word| ["%#{word}%", "%#{word}%"] }.flatten
    )
  }

  scope :my_projects, ->(user) {
    team_member_projects = where(team_members: {user: user})

    project_member_projects = where(project_members: {user: user, status: "confirmed"})

    team_member_projects.or(project_member_projects)
  }

  scope :my_administration_projects, ->(user) {
    where(owner: user)
      .or(Project.where(project_members: {user: user, admin: true}))
  }

  scope :by_tags, ->(tag_ids) {
    tag_ids = tag_ids.flatten.reject(&:blank?)

    joins(:tags)
      .where(tags: {
        id: tag_ids
      })
  }

  scope :by_school, ->(school_id) {
    where(school_levels: {
      school_id: Project.convert_to_array(school_id)
    })
  }

  scope :by_companies, ->(company_ids) {
    project_companies = ProjectCompany.where(company_id: company_ids)

    where(
      project_companies: project_companies
    )
  }

  scope :by_school_level, ->(school_level_id) {
    where(school_levels: {
      id: school_level_id
    })
  }

  def start_date_before_end_date
    return unless start_date > end_date

    errors.add(:start_date, "La date de début doit être avant la date de fin")
    errors.add(:end_date, "La date de fin doit être après la date de début")
  end

  def school_levels_or_company_presence
    return true if project_school_levels.present?
    return true if project_companies.present?

    errors.add(:project_school_levels, "Vous devez sélectionner au moins un niveau scolaire")
    errors.add(:school_levels, "Vous devez sélectionner au moins un niveau scolaire")
    errors.add(:project_companies, "Vous devez sélectionner au moins une entreprise")
  end

  def schools
    school_levels.map(&:school).uniq
  end

  def formatted_date_start
    start_date.strftime("%d/%m/%Y %H:%M")
  end

  def formatted_date_end
    end_date.strftime("%d/%m/%Y %H:%M")
  end

  def short_start_date
    start_date.strftime("%d/%m/%Y")
  end

  def short_end_date
    end_date.strftime("%d/%m/%Y")
  end

  def number_of_participants
    team_members.uniq.count
  end

  def self.convert_to_array(input)
    if input.is_a?(Array)
      return input.map(&:to_i)
    end

    if /^\[.*\]$/.match?(input) # Vérifie si la chaîne est entre crochets
      input[1..-2].split(",").map(&:to_i)
    else
      [input.to_i]
    end
  end

  def pending_participants?
    project_members.pending.any?
  end

  def pending_participants
    project_members.pending
  end

  def can_edit?(user)
    owner == user || project_members.where(user: user, admin: true).any?
  end

  def companies_full_name_joined
    companies.map(&:full_name).join(", ")
  end

  def have_companies
    companies.present?
  end
end
