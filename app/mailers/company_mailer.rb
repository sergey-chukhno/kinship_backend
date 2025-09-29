require "postmark-rails/templated_mailer"

class CompanyMailer < PostmarkRails::TemplatedMailer
  include Devise::Controllers::UrlHelpers
  default from: "support@kinshipedu.fr"

  def partnership_confirmed(company:, school:)
    @company = company
    @school = school

    self.template_model = {
      owner: @company.owner.user.full_name,
      company_name: @company.full_name,
      school_name: @school.full_name
    }

    mail to: @company.owner.user.email, postmark_template_alias: "partnership-confirmed"
  end
end
