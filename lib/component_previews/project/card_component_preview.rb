# frozen_string_literal: true

class Project::CardComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render Project::Card::CardComponent.new(project: Project.first)
  end
end
