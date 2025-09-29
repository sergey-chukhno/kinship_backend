require "postmark-rails/templated_mailer"

class ProjectMemberMailer < PostmarkRails::TemplatedMailer
  default from: "support@kinshipedu.fr"

  def notify_project_member_got_confirmed(project_member)
    @member = project_member.user
    @project = project_member.project

    self.template_model = {
      project_name: @project.title,
      project_member_full_name: @member.full_name
    }

    mail to: project_member.user.email, postmark_template_alias: "project-member-got-confirmed"
  end
end
