require "postmark-rails/templated_mailer"

class OrganizationMailer < PostmarkRails::TemplatedMailer
  include Devise::Controllers::UrlHelpers
  default from: "support@kinshipedu.fr"

  def notify_admins_of_pending_user_confirmation(organisation:, contact_mail:)
    @organisation = organisation
    @action_url = set_action_url

    self.template_model = {
      organisation_name: @organisation.full_name,
      action_url: @action_url
    }

    mail to: contact_mail, postmark_template_alias: "users-are-waiting-for-confirmation"
  end

  def notify_organization_confirmation(organisation:, owner:)
    @organisation = organisation
    @owner = owner

    self.template_model = {
      organisation_name: @organisation.full_name,
      owner_name: @owner.full_name
    }

    mail to: @owner.email, postmark_template_alias: "notify-organisation-confirmation"
  end

  private

  def set_action_url
    return school_admin_panel_school_member_url(@organisation, status: :pending) if @organisation.is_a?(School)

    company_admin_panel_company_member_url(@organisation, status: :pending)
  end
end
