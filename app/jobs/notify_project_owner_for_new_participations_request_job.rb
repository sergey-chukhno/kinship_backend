class NotifyProjectOwnerForNewParticipationsRequestJob < ApplicationJob
  queue_as :jobs

  def perform(*args)
    Project.select { |project| project.pending_participants? }.each do |project|
      ProjectMailer.notify_pending_participants_confirmation(project).deliver_later
    end
  end
end
