class CompanyType < ApplicationRecord
  has_one :company

  validates :name, presence: true
  validates :name, uniqueness: {case_sensitive: false}
end
