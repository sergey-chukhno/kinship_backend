require "postmark-rails/templated_mailer"

class SchoolLevelMailer < PostmarkRails::TemplatedMailer
  default from: "support@kinshipedu.fr"

  def school_level_creation_request(user_requestor_full_name:, user_requestor_email:, school:, school_level_wanted:)
    self.template_model = {
      name: user_requestor_full_name,
      requestor_email: user_requestor_email,
      school_name: school.full_name,
      action_url: new_admin_school_level_url(school_level: {school_id: school.id}),
      school_level_wanted:
    }

    email_to = Rails.env.production? ? "support@kinshipedu.fr" : "kinship@drakkar.io"

    mail to: email_to, postmark_template_alias: "school-level-creation-request"
  end
end
