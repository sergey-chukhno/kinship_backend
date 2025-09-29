# frozen_string_literal: true

class AdminPanelMemberCardComponent < ViewComponent::Base
  include SvgHelper
  include Devise::Controllers::Helpers

  def initialize(member:, school: nil, company: nil, project: nil, partnership: nil)
    @school = school
    @company = company
    @partnership = partnership
    @project = project
    @member = member
  end

  def role
    @partnership ? @member.company_type.name : t(@member.role, scope: [:models, :user, :roles])
  end

  def role_tag_color
    case role
    when "Parent"
      "green"
    when "Enseignant"
      "yellow"
    else
      "purple"
    end
  end

  def member_confirmed?
    return @member.user_schools.find_by(school: @school).confirmed? if @school
    return @member.user_company.find_by(company: @company).confirmed? if @company
    @member.school_companies.find_by(school: @partnership).confirmed? if @partnership
  end

  def update_confirmation_path
    return school_admin_panel_school_members_update_confirmation_path(id: @school, member_id: @member) if @school
    return company_admin_panel_company_members_update_confirmation_path(id: @company, member_id: @member) if @company
    school_admin_panel_partnership_path(id: @partnership, member_id: @member) if @partnership
  end

  def member_can_access_badges?
    return @member.user_schools.find_by(school: @school).can_access_badges? if @school
    @member.user_company.find_by(company: @company).can_access_badges? if @company
  end

  def update_can_access_badges_path
    return school_admin_panel_school_members_update_can_access_badges_path(id: @school, member_id: @member) if @school
    company_admin_panel_company_members_update_can_access_badges_path(id: @company, member_id: @member) if @company
  end

  def update_admin_path
    return school_admin_panel_school_members_update_admin_path(id: @school, member_id: @member) if @school
    company_admin_panel_company_members_update_admin_path(id: @company, member_id: @member) if @company
  end

  def destroy_path
    return school_admin_panel_school_member_path(id: @school, member_id: @member, status: params[:status]) if @school
    return company_admin_panel_company_member_path(id: @company, member_id: @member, status: params[:status]) if @company
    school_admin_panel_partnership_destroy_partnership_path(id: @partnership, member_id: @member) if @partnership
  end

  def member_school_or_member_company
    return @member.user_schools.find_by(school: @school) if @school
    return @member.user_company.find_by(company: @company) if @company
    @member.school_companies.find_by(school: @partnership) if @partnership
  end

  def owner?
    return false if @partnership
    member_school_or_member_company.owner?
  end
end
