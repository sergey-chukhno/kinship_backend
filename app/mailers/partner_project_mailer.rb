class PartnerProjectMailer < ApplicationMailer
  def notify_new_partner_project(admin_user, project, organization)
    @admin_user = admin_user
    @project = project
    @organization = organization
    @partnership = project.partnership
    @project_url = project_url(@project)
    
    mail(
      to: @admin_user.email,
      subject: "Nouveau projet partenaire: #{@project.title}"
    )
  end
end
