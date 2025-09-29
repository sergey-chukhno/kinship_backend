class CompanyApiAccess < ApplicationRecord
  belongs_to :api_access
  belongs_to :company
end
