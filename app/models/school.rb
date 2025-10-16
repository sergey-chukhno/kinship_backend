class School < ApplicationRecord
  # == Schema Information
  #
  # Table name: schools
  #
  # id                      :bigint     not null, primary key
  # name                    :string     not null
  # zip_code                :string     not null
  # city                    :string     not null
  # school_type             :integer    not null
  # status                  :integer    not null
  # referent_phone_number   :string
  #

  include PgSearch::Model

  has_many :school_levels, dependent: :destroy
  has_many :user_schools, dependent: :destroy
  has_many :users, through: :user_schools
  has_many :school_companies, dependent: :destroy
  has_many :companies, through: :school_companies
  has_many :contracts, dependent: :destroy

  has_one_attached :logo

  accepts_nested_attributes_for :school_levels, allow_destroy: true

  enum :school_type, [:primaire, :college, :lycee, :erea, :medico_social, :service_administratif, :information_et_orientation, :autre], default: :primaire
  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :name, :zip_code, :school_type, :city, :status, presence: true
  validate :logo_format

  pg_search_scope :by_full_name, against: [:name, :city, :zip_code],
    using: {
      tsearch: {
        prefix: true
      }
    }

  scope :by_zip_code, ->(zip_code) { where(zip_code:) }
  scope :by_school_type, ->(school_type) { where(school_type:) }

  def full_name
    "#{name}, #{city} (#{zip_code})"
  end

  def owner?
    user_schools.where(owner: true).any?
  end

  def owner
    user_schools.find_by(owner: true)
  end

  def admins?
    user_schools.where(admin: true).any?
  end

  def admins
    user_schools.where(admin: true)
  end

  def users_waiting_for_confirmation?
    user_schools.where(status: :pending).any?
  end

  def users_waiting_for_confirmation
    user_schools.where(status: :pending)
  end

  def companies_waiting_for_confirmation?
    school_companies.where(status: :pending).any?
  end

  def active_contract?
    contracts.where(active: true).any?
  end

  def active_contract
    contracts.find_by(active: true)
  end

  def logo_url
    return nil unless logo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(logo, only_path: false)
  end

  private

  def logo_format
    return unless logo.attached?

    acceptable_types = ["image/jpeg", "image/png", "image/gif", "image/webp", "image/svg+xml"]
    unless acceptable_types.include?(logo.content_type)
      errors.add(:logo, "doit être une image JPEG, PNG, GIF, WebP ou SVG")
    end

    if logo.byte_size > 5.megabytes
      errors.add(:logo, "doit être inférieure à 5 Mo")
    end
  end
end
