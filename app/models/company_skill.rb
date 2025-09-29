class CompanySkill < ApplicationRecord
  belongs_to :company
  belongs_to :skill
end
