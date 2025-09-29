class CompanyCompany < ApplicationRecord
  belongs_to :company_sponsor, class_name: "Company"
  belongs_to :company

  enum :status, {pending: 0, confirmed: 1}, default: :pending

  validates :status, presence: true
  validates :company_id, uniqueness: {scope: :company_sponsor_id}
  validate :no_reverse_sponsorship

  private

  def no_reverse_sponsorship
    if CompanyCompany.exists?(company_id: company_sponsor_id, company_sponsor_id: company_id)
      errors.add(:base, "Reverse sponsorship already exists")
    end
  end
end
