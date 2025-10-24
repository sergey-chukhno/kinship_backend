class BranchRequestMailer < ApplicationMailer
  # Send email when branch request is created
  # @param branch_request [BranchRequest] The branch request
  # @param recipient_organization [School/Company] The organization receiving the request
  def branch_request_created(branch_request, recipient_organization)
    @branch_request = branch_request
    @initiator = branch_request.initiator
    @parent = branch_request.parent
    @child = branch_request.child
    @recipient_organization = recipient_organization
    @recipient_admin_emails = get_admin_emails(recipient_organization)
    
    return if @recipient_admin_emails.empty?
    
    mail(
      to: @recipient_admin_emails,
      subject: "Nouvelle demande de branche de #{@initiator.name}"
    )
  end
  
  # Send email when branch request is confirmed
  # @param branch_request [BranchRequest] The branch request
  # @param initiator [School/Company] The initiator to notify
  def branch_request_confirmed(branch_request, initiator)
    @branch_request = branch_request
    @parent = branch_request.parent
    @child = branch_request.child
    @initiator = initiator
    @initiator_admin_emails = get_admin_emails(initiator)
    
    return if @initiator_admin_emails.empty?
    
    mail(
      to: @initiator_admin_emails,
      subject: "Demande de branche confirmée"
    )
  end
  
  # Send email when branch request is rejected
  # @param branch_request [BranchRequest] The branch request
  # @param initiator [School/Company] The initiator to notify
  def branch_request_rejected(branch_request, initiator)
    @branch_request = branch_request
    @parent = branch_request.parent
    @child = branch_request.child
    @initiator = initiator
    @initiator_admin_emails = get_admin_emails(initiator)
    
    return if @initiator_admin_emails.empty?
    
    mail(
      to: @initiator_admin_emails,
      subject: "Demande de branche refusée"
    )
  end
  
  private
  
  def get_admin_emails(organization)
    if organization.is_a?(School)
      organization.user_schools
                  .where(role: [:admin, :superadmin], status: :confirmed)
                  .joins(:user)
                  .pluck('users.email')
                  .compact
    elsif organization.is_a?(Company)
      organization.user_companies
                  .where(role: [:admin, :superadmin], status: :confirmed)
                  .joins(:user)
                  .pluck('users.email')
                  .compact
    else
      []
    end
  end
end

