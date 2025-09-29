class DestroyUserNotConfirmedAfter48HoursJob < ApplicationJob
  queue_as :jobs

  def perform(*args)
    User.where(confirmed_at: nil).where("confirmation_sent_at < ?", 48.hours.ago).destroy_all
  end
end
