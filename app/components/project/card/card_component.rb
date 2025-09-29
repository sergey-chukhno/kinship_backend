# frozen_string_literal: true

class Project::Card::CardComponent < ViewComponent::Base
  include SvgHelper

  with_collection_parameter :project

  def initialize(project:)
    @project = project
  end

  private

  def custom_image?
    @project.main_picture.attached?
  end

  def school_project?
    @project.schools.present?
  end

  def school_levels
    @project.school_levels.map { |school_level| school_level.full_name_without_school }.join(", ")
  end
end
