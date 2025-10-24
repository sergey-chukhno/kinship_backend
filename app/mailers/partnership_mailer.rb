class PartnershipMailer < ApplicationMailer
  # Send email when partnership request is created
  # @param partnership [Partnership] The partnership
  # @param partner_organization [School/Company] The invited partner
  def partnership_request_created(partnership, partner_organization)
    @partnership = partnership
    @initiator = partnership.initiator
    @partner_organization = partner_organization
    @partner_admin_emails = get_admin_emails(partner_organization)
    
    return if @partner_admin_emails.empty?
    
    mail(
      to: @partner_admin_emails,
      subject: "Nouvelle demande de partenariat de #{@initiator.name}"
    )
  end
  
  # Send email when partnership is confirmed
  # @param partnership [Partnership] The partnership
  # @param confirming_organization [School/Company] The organization that confirmed
  # @param initiator [School/Company] The initiator to notify
  def partnership_confirmed(partnership, confirming_organization, initiator)
    @partnership = partnership
    @confirming_organization = confirming_organization
    @initiator = initiator
    @initiator_admin_emails = get_admin_emails(initiator)
    
    return if @initiator_admin_emails.empty?
    
    mail(
      to: @initiator_admin_emails,
      subject: "Partenariat confirmé avec #{@confirming_organization.name}"
    )
  end
  
  # Send email when partnership is rejected
  # @param partnership [Partnership] The partnership
  # @param rejecting_organization [School/Company] The organization that rejected
  # @param initiator [School/Company] The initiator to notify
  def partnership_rejected(partnership, rejecting_organization, initiator)
    @partnership = partnership
    @rejecting_organization = rejecting_organization
    @initiator = initiator
    @initiator_admin_emails = get_admin_emails(initiator)
    
    return if @initiator_admin_emails.empty?
    
    mail(
      to: @initiator_admin_emails,
      subject: "Demande de partenariat refusée par #{@rejecting_organization.name}"
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

