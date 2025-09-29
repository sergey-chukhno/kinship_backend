class SchoolAdminPanel::PartnershipsController < SchoolAdminPanel::BaseController
  def show
    @partnerships = @school.school_companies
  end

  def update
    @partnership = SchoolCompany.find_by(school: @school, company_id: params[:member_id])
    @status = (@partnership.status == "pending") ? "confirmed" : "pending"

    @partnership.update(status: @status)

    if @status.eql?("confirmed")
      notify_company_owner(@partnership.company, @school)
    end
  end

  def destroy_partnership
    @partnership = SchoolCompany.find_by(school: @school, company_id: params[:member_id])

    @partnership.destroy ? flash[:notice] = "Partenariat supprimé avec succès" : flash[:alert] = "Une erreur est survenue"
    redirect_to school_admin_panel_partnership_path(@school)
  end

  private

  def notify_company_owner(company, school)
    CompanyMailer.partnership_confirmed(company: company, school: school).deliver_later
  end
end
