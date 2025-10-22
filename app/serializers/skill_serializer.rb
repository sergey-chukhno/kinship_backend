# Skill serializer for API responses
class SkillSerializer < ActiveModel::Serializer
  attributes :id, :name, :official
  
  # Full by default (user preference: Option C)
  has_many :sub_skills, serializer: SubSkillSerializer
end

