# SubSkill serializer for API responses
class SubSkillSerializer < ActiveModel::Serializer
  attributes :id, :name, :skill_id
  
  belongs_to :skill, serializer: SkillSerializer
end

