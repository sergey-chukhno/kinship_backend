# Preview all emails at http://localhost:3000/rails/mailers/partner_project
class PartnerProjectPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/partner_project/notify_new_partner_project
  def notify_new_partner_project
    PartnerProjectMailer.notify_new_partner_project
  end

end
