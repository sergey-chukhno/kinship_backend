class Link < ApplicationRecord
  belongs_to :project

  before_validation :strip_url

  validates :url, :name, presence: true
  validates :url, uniqueness: {scope: :project_id}
  validate :validate_url, if: -> { url.present? }

  private

  def strip_url
    self.url = url.strip if url.present?
  end

  def validate_url
    uri = URI.parse(url)
    errors.add(:url, "L'url doit commencer par 'https://'") unless valid_url?(uri)
  rescue URI::InvalidURIError
    errors.add(:url, "L'url est invalide")
  end

  def valid_url?(uri)
    uri.is_a?(URI::HTTPS) && uri.host.present?
  end
end
