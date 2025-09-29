require "postmark-rails/templated_mailer"

class SchoolMailer < PostmarkRails::TemplatedMailer
  include Devise::Controllers::UrlHelpers
  default from: "support@kinshipedu.fr"

  def notify_admins_of_pending_partnership_confirmation(school:, contact_mail:)
    @school = school

    self.template_model = {
      school_name: @school.full_name,
      action_url: school_admin_panel_partnership_url(@school)
    }

    mail to: contact_mail, postmark_template_alias: "notify-admins-of-pending-partnership-confirmation"
  end
end
