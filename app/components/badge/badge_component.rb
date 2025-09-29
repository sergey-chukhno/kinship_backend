# frozen_string_literal: true

class Badge::BadgeComponent < ViewComponent::Base
  with_collection_parameter :badge

  def initialize(badge:)
    @badge = badge
  end
end
