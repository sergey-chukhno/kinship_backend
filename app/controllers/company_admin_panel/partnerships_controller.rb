class CompanyAdminPanel::PartnershipsController < CompanyAdminPanel::BaseController
  def edit
    @schools = @company.schools
    @company_partners = @company.company_partners
    @wanted_conpany_partners = @company.reverse_company_partners
  end

  def update
    @company.update(company_params) ? flash[:success] = "Les écoles ont bien été mises à jour" : flash[:error] = "Une erreur est survenue"
    redirect_to edit_company_admin_panel_partnership_path(@company)
  end

  def update_sponsor_confirmation
    @sponsor = CompanyCompany.find(params[:sponsor_id])
    if @sponsor.confirmed?
      @sponsor.update(status: "pending")
    else
      @sponsor.update(status: "confirmed")
    end
  end

  def destroy_sponsor
    @sponsor = CompanyCompany.find(params[:sponsor_id])
    @sponsor.destroy ? flash[:notice] = "Partenariat supprimé avec succès" : flash[:alert] = "Une erreur est survenue"

    redirect_to edit_company_admin_panel_partnership_path(@company)
  end

  private

  def company_params
    params
      .require(:company)
      .permit(
        school_companies_attributes: [:id, :school_id],
        company_partners_attributes: [:id, :company_id]
      )
  end
end
