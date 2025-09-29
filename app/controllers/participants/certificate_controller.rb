class Participants::CertificateController < Participants::BaseController
  before_action :set_participant, only: [:update]

  def update
    authorize @participant, policy_class: Participants::CertificatePolicy
    @participant.update(certify: !@participant.certify)

    respond_to do |format|
      format.turbo_stream { render template: "participants/certificates/update" }
    end
  end

  private

  def set_participant
    authorize @participant = User.find(params[:id]), policy_class: Participants::CertificatePolicy
  end
end
