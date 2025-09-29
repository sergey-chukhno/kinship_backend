class SendEmailToOrganizationAdminJob < ApplicationJob
  queue_as :jobs

  def perform(*args)
    send_email_to_organization_admins(School.all)
    send_email_to_organization_admins(Company.all)
  end

  private

  def send_email_to_organization_admins(organizations)
    organizations.each do |organization|
      next unless organization.users_waiting_for_confirmation?

      contacts_mail = organization.owner? ? organization.admins.map(&:user).pluck(:email) : User.admin.pluck(:email)

      contacts_mail.each do |contact_mail|
        OrganizationMailer.notify_admins_of_pending_user_confirmation(organisation: organization, contact_mail: contact_mail).deliver_later
      end
    end
  end
end
