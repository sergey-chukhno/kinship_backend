require "postmark-rails/templated_mailer"

class UserBadgeMailer < PostmarkRails::TemplatedMailer
  default from: "support@kinshipedu.fr"

  def notify_badge_approved(sender:, receiver:, badge:, organization:, project_title:)
    self.template_model = {
      sender: sender.full_name,
      receiver: receiver.full_name,
      badge: badge.name,
      badge_level: badge.level,
      project: project_title,
      organization: organization.full_name,
      action_url: account_profile_badges_tree_url(receiver.id)
    }

    mail to: receiver.email, postmark_template_alias: "notify_badge_approved"
  end
end
