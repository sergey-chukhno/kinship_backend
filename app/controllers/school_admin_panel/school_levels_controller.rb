class SchoolAdminPanel::SchoolLevelsController < SchoolAdminPanel::BaseController
  def create
    @custom_school_level = Custom::CustomSchoolLevel.new(custom_school_level_params)

    if @custom_school_level.valid?
      SchoolLevelMailer.school_level_creation_request(
        user_requestor_full_name: current_user.full_name,
        user_requestor_email: current_user.email,
        school: @school,
        school_level_wanted: @custom_school_level.full_name
      ).deliver_later

      redirect_to edit_school_admin_panel_school_level_path(@school), notice: "Votre demande d'ajout de classe a bien été envoyée"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @school.update(school_level_params)
      redirect_to edit_school_admin_panel_school_level_path(@school), notice: "Les niveaux ont bien été mis à jour"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_school
    super
    @school_level_levels_collection = set_school_level_levels_collection(@school)
    @school_level_names_collection = SchoolLevel::LEVEL_NAMES
    @custom_school_level = Custom::CustomSchoolLevel.new
  end

  def school_level_params
    params.require(:school).permit(school_levels_attributes: [:id, :level, :name])
  end

  def custom_school_level_params
    params.require(:custom_custom_school_level).permit(:level, :name, :school_id)
  end

  def set_school_level_levels_collection(school)
    return SchoolLevel::PRIMARY_SCHOOL_LEVEL.map { |level| [t(level, scope: [:layouts, :school_admin_panel, :school_level, :edit_form, :levels]), level] } if school.school_type == "primaire"
    return SchoolLevel::SECONDARY_SCHOOL_LEVEL.map { |level| [t(level, scope: [:layouts, :school_admin_panel, :school_level, :edit_form, :levels]), level] } if school.school_type == "college"
    return SchoolLevel::HIGH_SCHOOL_LEVEL.map { |level| [t(level, scope: [:layouts, :school_admin_panel, :school_level, :edit_form, :levels]), level] } if school.school_type == "lycee"

    SchoolLevel::LEVEL.map { |level| [t(level, scope: [:layouts, :school_admin_panel, :school_level, :edit_form, :levels]), level] }
  end
end
