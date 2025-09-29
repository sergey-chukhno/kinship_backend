class DestroyLoggingWhenTheyAreOneYearAndOneDayOldJob < ApplicationJob
  queue_as :jobs

  def perform(*args)
    Logging.where("created_at < ?", 1.year.ago).destroy_all
  end
end
