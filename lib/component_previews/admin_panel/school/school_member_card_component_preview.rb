# frozen_string_literal: true

class AdminPanel::School::SchoolMemberCardComponentPreview < ViewComponent::Preview
  layout "lookbook"

  def default
    render(AdminPanel::School::SchoolMemberCard::SchoolMemberCardComponent.new(UserSchool.first))
  end
end
