# frozen_string_literal: true

class AdminPanel::School::SchoolMemberCard::SchoolMemberCardComponent < ViewComponent::Base
  def initialize(school_member)
    @school_member = school_member
    @member = school_member.user
  end
end
