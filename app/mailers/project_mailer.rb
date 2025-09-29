require "postmark-rails/templated_mailer"

class ProjectMailer < PostmarkRails::TemplatedMailer
  include Devise::Controllers::UrlHelpers
  default from: "support@kinshipedu.fr"

  def new_project_notification(user:, project:)
    @user = user
    @project = project
    @school_levels = @project.school_levels.map(&:full_name).join(", ")

    self.template_model = {
      name: @user.full_name,
      project_title: @project.title,
      project_url: project_url(@project),
      project_school_levels: @school_levels
    }

    mail to: @user.preferred_email, postmark_template_alias: "new-project-notification"
  end

  def participate_request(project:, message:, user:)
    owner = project.owner

    self.template_model = {
      project_name: project.title,
      message: message,
      user_full_name: user.full_name,
      user_email: user.preferred_email,
      owner_full_name: owner.full_name,
      owner_email: owner.preferred_email
    }

    mail to: owner.preferred_email, postmark_template_alias: "project-participate-request"
  end

  def notify_pending_participants_confirmation(project)
    @project = project
    @owner = @project.owner

    self.template_model = {
      project_name: @project.title,
      action_url: project_admin_panel_project_member_url(@project, status: :pending)
    }

    mail to: @owner.preferred_email, postmark_template_alias: "notify-pending-participants-confirmation"
  end
end
