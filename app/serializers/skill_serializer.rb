# Skill serializer for API responses
class SkillSerializer < ActiveModel::Serializer
  attributes :id, :name, :official
  
  has_many :sub_skills, if: -> { instance_options[:include_sub_skills] }
end

