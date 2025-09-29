class NotifySchoolsAdminsForNewPartnershipsJob < ApplicationJob
  queue_as :jobs

  def perform(*args)
    School.confirmed.each do |school|
      next unless school.companies_waiting_for_confirmation?

      contacts_mail = school.owner? ? school.admins.map(&:user).pluck(:email) : User.admin.pluck(:email)

      contacts_mail.each do |contact_mail|
        SchoolMailer.notify_admins_of_pending_partnership_confirmation(school: school, contact_mail: contact_mail).deliver_later
      end
    end
  end
end
