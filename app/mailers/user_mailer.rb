require "postmark-rails/templated_mailer"

class UserMailer < PostmarkRails::TemplatedMailer
  include Devise::Controllers::UrlHelpers
  default from: "support@kinshipedu.fr"

  def reset_password_instructions(record, token, opts = {})
    @user = record
    @token = token

    self.template_model = {
      name: "#{@user[:first_name]} #{@user[:last_name]}",
      action_url: edit_password_url(@user, reset_password_token: @token)
    }

    mail to: @user.preferred_email, postmark_template_alias: "reset-password-instructions"
  end

  def request_participation_to_project(owner:, participant:, message:, project: nil)
    title_project = project.nil? ? "Projet en cours de création" : project.title

    self.template_model = {
      name: participant.full_name,
      owner_name: owner.full_name,
      owner_email: owner.preferred_email,
      project_name: title_project,
      message:
    }

    mail to: participant.preferred_email, postmark_template_alias: "request-participation-to-project"
  end

  def send_welcome_email(user)
    self.template_model = {
      name: user.full_name,
      email: user.email
    }

    mail to: user.preferred_email, postmark_template_alias: "welcome-email"
  end

  def confirmation_instructions(record, token, opts = {})
    @user = record
    @token = token

    self.template_model = {
      name: @user.full_name,
      action_url: confirmation_url(@user, confirmation_token: @token)
    }

    mail to: @user.preferred_email, postmark_template_alias: "email-confirmation"
  end

  def delete_account_instruction(user)
    self.template_model = {
      name: user.full_name,
      email: user.email,
      action_url: account_delete_account_url(user, delete_token: user.delete_token)
    }

    mail to: user.preferred_email, postmark_template_alias: "delete-account-instruction"
  end

  def delete_account_confirmation(user)
    self.template_model = {
      name: user[:name],
      email: user[:email]
    }

    mail to: user[:email], postmark_template_alias: "delete-account-confirmation"
  end

  def contact_participant(subject:, message:, sender:, recipient:)
    self.template_model = {
      subject: subject,
      message: message,
      sender_name: sender.full_name,
      sender_email: sender.preferred_email,
      recipient_name: recipient.full_name
    }

    mail to: recipient.preferred_email, postmark_template_alias: "contact-participant"
  end
end
