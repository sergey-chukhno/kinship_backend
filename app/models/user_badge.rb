class UserBadge < ApplicationRecord
  has_many_attached :documents
  has_many :user_badge_skills, dependent: :destroy
  has_many :badge_skills, through: :user_badge_skills

  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"
  belongs_to :badge
  belongs_to :project, optional: true
  belongs_to :organization, polymorphic: true

  enum :status, {pending: 0, approved: 1, rejected: 2}, default: :pending

  accepts_nested_attributes_for :user_badge_skills

  before_validation :set_status, if: :status

  validates :project_title, :project_description, :status, presence: true
  validates :organization_type, inclusion: {in: %w[School Company IndependentTeacher]}
  validate :validate_documents

  before_save :notify_badge_approved, if: :badge_got_approved?

  def document_urls
    documents.map { |doc| Rails.application.routes.url_helpers.url_for(doc) }
  end

  def domains
    badge_skills.where(category: "domain")
  end

  def expertises
    badge_skills.where(category: "expertise")
  end

  private

  def validate_documents
    return true if badge.blank? || badge.level_1? || documents.attached?

    errors.add(:documents, "Vous devez joindre au moins un document")
  end

  def set_status
    return if approved? || rejected?
    return unless badge&.level_1?

    self.status = :approved
  end

  def badge_got_approved?
    status_changed? && approved? || new_record? && approved?
  end

  def notify_badge_approved
    UserBadgeMailer.notify_badge_approved(
      sender:,
      receiver:,
      badge:,
      organization:,
      project_title:
    ).deliver_later
  end
end
