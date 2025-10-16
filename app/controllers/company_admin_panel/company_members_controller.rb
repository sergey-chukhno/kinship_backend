class CompanyAdminPanel::CompanyMembersController < CompanyAdminPanel::BaseController
  skip_before_action :set_company, only: [:destroy]
  before_action :redirect_to_members_pending_path_if_wrong_status_param, only: [:show]
  before_action :set_company_member, only: [:update_confirmation, :update_role, :destroy]

  def show
    @company = authorize Company.find(params[:id]), policy_class: CompanyAdminPanel::BasePolicy
    @company_members = UserCompany.where(company: @company, status: params[:status]).where.not(user: current_user)
  end

  def update_confirmation
    if @company_member.confirmed?
      @company_member.update(status: :pending)
    else
      @company_member.update(status: :confirmed)
    end
  end

  def update_role
    new_role = params[:role]
    
    # Prevent non-superadmin from creating/modifying superadmin
    current_user_company = current_user.user_company.find_by(company: @company_member.company)
    if new_role == 'superadmin' && !current_user_company&.superadmin?
      flash[:alert] = "Seul un superadmin peut nommer un autre superadmin"
      return redirect_back(fallback_location: root_path)
    end
    
    @company_member.update(role: new_role)
    redirect_back(fallback_location: root_path, notice: "Rôle mis à jour")
  end

  def destroy
    @company_member.destroy
    redirect_to company_admin_panel_company_member_path(@company_member.company_id, status: params[:status]), notice: "Membre supprimé avec succès"
  end

  private

  def set_company_member
    @company_member = authorize UserCompany.find(params[:id]), policy_class: CompanyAdminPanel::BasePolicy
  end

  def redirect_to_members_pending_path_if_wrong_status_param
    redirect_to company_admin_panel_company_member_path(@company, status: :pending) unless ["pending", "confirmed"].include?(params[:status])
  end
end
