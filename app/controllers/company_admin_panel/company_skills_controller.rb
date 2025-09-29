class CompanyAdminPanel::CompanySkillsController < CompanyAdminPanel::BaseController
  def edit
    @skills = Skill.officials.includes(:sub_skills)
  end

  def update
    if @company.update(skills_params)
      redirect_to edit_company_admin_panel_company_skill_path(@company), notice: "Compétences mises à jour avec succès"
    else
      redirect_to edit_company_admin_panel_company_skill_path(@company), alert: "Une erreur est survenue"
    end
  end

  private

  def skills_params
    params.require(:company).permit(skill_ids: [], sub_skill_ids: [])
  end
end
