require "postmark-rails/templated_mailer"

class AdminMailer < PostmarkRails::TemplatedMailer
  default from: "support@kinshipedu.fr"

  def account_deleted(user)
    self.template_model = {
      name: user[:name],
      email: user[:email]
    }

    mail to: "support@kinshipedu.fr", postmark_template_alias: "account-deleted"
  end

  def notify_admin_on_organization_creation(organisation_type:, organisation_name:, admin_email:)
    self.template_model = {
      name: "Kinship Admin",
      organisation_type: (organisation_type == "school") ? "Ecole" : "Association",
      organisation_name:
    }

    mail to: admin_email, postmark_template_alias: "notify_admin_on_organization_creation"
  end
end
