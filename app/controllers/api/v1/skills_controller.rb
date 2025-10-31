# Skills API controller
# Public endpoints for skills and sub-skills (no authentication required)
class Api::V1::SkillsController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:index, :sub_skills]
  
  # GET /api/v1/skills
  # List all skills (public endpoint)
  # @return [JSON] Array of skill objects with nested sub_skills
  def index
    @skills = Skill.includes(:sub_skills).order(:name)
    
    render json: {
      data: @skills.map { |skill| serialize_skill(skill) }
    }
  end
  
  # GET /api/v1/skills/:id/sub_skills
  # List sub-skills for a specific skill (public endpoint)
  # @param id [Integer] Skill ID
  # @return [JSON] Array of sub-skill objects
  def sub_skills
    @skill = Skill.find_by(id: params[:id])
    
    unless @skill
      return render json: {
        error: 'Not Found',
        message: 'Skill not found'
      }, status: :not_found
    end
    
    render json: {
      skill: serialize_skill(@skill),
      sub_skills: @skill.sub_skills.order(:name).map { |sub_skill| serialize_sub_skill(sub_skill) }
    }
  end
  
  private
  
  def serialize_skill(skill)
    {
      id: skill.id,
      name: skill.name,
      official: skill.official,
      sub_skills: skill.sub_skills.order(:name).map { |sub_skill| serialize_sub_skill(sub_skill) }
    }
  end
  
  def serialize_sub_skill(sub_skill)
    {
      id: sub_skill.id,
      name: sub_skill.name
    }
  end
end

