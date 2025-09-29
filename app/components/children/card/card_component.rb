# frozen_string_literal: true

class Children::Card::CardComponent < ViewComponent::Base
  with_collection_parameter :children

  def initialize(children:)
    super

    @children = children
    @school = children.schools&.first
    @school_level = children.school_levels&.first
    @company = children.companies&.first
  end
end
