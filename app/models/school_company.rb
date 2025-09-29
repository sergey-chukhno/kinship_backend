class SchoolCompany < ApplicationRecord
  belongs_to :school
  belongs_to :company

  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :status, presence: true
  validates :company_id, uniqueness: {scope: :school_id}
end
