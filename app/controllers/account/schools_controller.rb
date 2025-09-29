class Account::SchoolsController < ApplicationController
  before_action :set_user, only: [:edit, :update]
  layout "account"

  def edit
    @user_schools = @user.schools
  end

  def update
    @user_schools = @user.schools

    if @user.update!(school_params)
      request_school_level_creation
      redirect_to edit_account_school_path(@user), notice: "Établissements mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user_school = UserSchool.find(params[:id]), policy_class: Account::SchoolsPolicy
    @user = @user_school.user
    @user_school_levels = @user.user_school_levels.joins(:school_level).where(school_level: {school_id: @user_school.school_id})

    if @user_school.destroy
      @user_school_levels.destroy_all
      redirect_to edit_account_school_path(@user), notice: "Établissement supprimé"
    else
      redirect_to edit_account_school_path(@user), alert: "Une erreur est survenue"
    end
  end

  private

  def request_school_level_creation
    params_custom_school_level = permit_request_school_level_creation_params[:request_school_level_creation].to_h

    params_custom_school_level.each do |key, value|
      params_custom_school_level.delete(key) if value["name"].blank? || value["level"].blank? || value["school_id"].blank?
    end => request_school_level_creation

    return if request_school_level_creation.empty?

    request_school_level_creation.each do |school_level|
      # school_level => ["<timestamp>", {"name"=>"Nom de la classe", "level"=>"Nom du level", "school_id"=>"<id school>"}]
      # on garde uniquement la deuxieme valeur. La premiere est le timestamp
      send_request_custom_school_level_mailer(school_level[1])
    end
  end

  def send_request_custom_school_level_mailer(school_level)
    SchoolLevelMailer.school_level_creation_request(
      user_requestor_full_name: @user.full_name,
      user_requestor_email: @user.email,
      school: School.find(school_level["school_id"]),
      school_level_wanted: school_level["level"] + " " + school_level["name"]
    ).deliver_later
  end

  def permit_request_school_level_creation_params
    params.permit(request_school_level_creation: [:name, :level, :school_id])
  end

  def set_user
    authorize @user = User.includes(:schools, :school_levels).find(params[:id]), policy_class: Account::SchoolsPolicy
  end

  def school_params
    params.require(:user).permit(user_schools_attributes: [:school_id], user_school_levels_attributes: [:id, :school_level_id, :_destroy])
  end
end
