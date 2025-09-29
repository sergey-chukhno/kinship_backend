class Participants::ContactsController < Participants::BaseController
  def new
    @contact = authorize Custom::ContactParticipant.new(recipient_id: params[:recipient_id], sender_id: current_user.id), policy_class: Participants::ContactPolicy
  end

  def create
    @contact = authorize Custom::ContactParticipant.new(contact_params), policy_class: Participants::ContactPolicy

    if @contact.valid?
      UserMailer.contact_participant(
        subject: @contact.subject,
        message: @contact.message,
        sender: User.find(@contact.sender_id),
        recipient: User.find(@contact.recipient_id)
      ).deliver_later

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to participants_path }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:custom_contact_participant).permit(
      :subject,
      :message,
      :sender_id,
      :recipient_id
    )
  end
end
