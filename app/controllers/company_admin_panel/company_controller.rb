class CompanyAdminPanel::CompanyController < CompanyAdminPanel::BaseController
  before_action :set_company, only: [:edit, :update]

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to company_admin_panel_company_path(@company), notice: "Organisation mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = authorize Company.find(params[:id]), policy_class: CompanyAdminPanel::BasePolicy
  end

  def company_params
    params.require(:company).permit(:email, :job, :take_trainee, :propose_workshop, :propose_summer_job)
  end
end
