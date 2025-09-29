class ApiAccess < ApplicationRecord
  before_validation :generate_token, on: :create

  has_many :company_api_accesses, dependent: :destroy
  has_many :companies, through: :company_api_accesses

  accepts_nested_attributes_for :company_api_accesses, allow_destroy: true

  validates :token, :name, presence: true
  validates :token, uniqueness: true

  private

  def generate_token
    loop do
      self.token = SecureRandom.hex(20)
      break unless ApiAccess.exists?(token: token)
    end
  end
end
