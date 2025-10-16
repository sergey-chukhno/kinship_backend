class SchoolAdminPanel::SchoolMembersController < SchoolAdminPanel::BaseController
  skip_before_action :set_school, only: [:destroy]
  before_action :redirect_to_members_pending_path_if_wrong_status_param, only: [:show]
  before_action :set_school_member, only: [:update_school_level, :update_confirmation, :update_role, :destroy]

  def show
    @school = authorize School.find(params[:id]), policy_class: SchoolAdminPanel::BasePolicy
    @school_members = @school.user_schools.where(school: @school, status: params[:status]).where.not(user: current_user)
  end

  def update_school_level
    @member = @school_member.user
    @member.update(school_level_params)

    render turbo_stream:
      turbo_stream.replace("#{helpers.dom_id(@school_member)}_update_school_level",
        partial: "school_level_form",
        locals: {school_member: @school_member})
  end

  def update_confirmation
    if @school_member.confirmed?
      @school_member.update(status: :pending)
    else
      @school_member.update(status: :confirmed)
    end
  end

  def update_role
    new_role = params[:role]
    
    # Prevent non-superadmin from creating/modifying superadmin
    current_user_school = current_user.user_schools.find_by(school: @school_member.school)
    if new_role == 'superadmin' && !current_user_school&.superadmin?
      flash[:alert] = "Seul un superadmin peut nommer un autre superadmin"
      return redirect_back(fallback_location: root_path)
    end
    
    @school_member.update(role: new_role)
    redirect_back(fallback_location: root_path, notice: "Rôle mis à jour")
  end

  def destroy
    @school_member.destroy
    redirect_to school_admin_panel_school_member_path(@school_member.school_id, status: params[:status]), notice: "Membre supprimé avec succès"
  end

  private

  def redirect_to_members_pending_path_if_wrong_status_param
    redirect_to school_admin_panel_school_member_path(@school, status: :pending) unless ["pending", "confirmed"].include?(params[:status])
  end

  def set_school_member
    @school_member = authorize UserSchool.find(params[:id]), policy_class: SchoolAdminPanel::BasePolicy
  end

  def school_level_params
    params.require(:user).permit(user_school_levels_attributes: [:id, :school_level_id, :user_id, :_destroy])
  end
end
