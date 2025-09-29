module ProjectHelper
  def define_project_status_svg(status)
    case status
    when "A venir"
      "in_progress.svg"
    when "En cours"
      "clock_counter_clockwise.svg"
    when "Terminé"
      "check_circle.svg"
    else
      "in_progress.svg"
    end
  end

  def display_projects_schools(project)
    return "" if project.schools.empty?

    (project.schools.count > 1) ? "#{project.schools.first.full_name}, ..." : project.schools.first.full_name
  end

  def display_projects_school_levels(project)
    project.school_levels.map { |school_level| school_level.full_name_without_school }.uniq.join(", ")
  end

  def display_projects_school_levels_name(project)
    project.school_levels.map { |school_level| school_level.level_name }.uniq.join(", ")
  end

  def define_project_status_color(project)
    project.ended? ? "color-var-2" : "primary"
  end

  def my_projects?
    return false if params["my_projects"].nil?

    params["my_projects"].to_i == 1
  end

  def my_administration_projects?
    return false if params["my_administration_projects"].nil?

    params["my_administration_projects"].to_i == 1
  end

  def my_schools?
    return false if params["my_schools"].nil?

    params["my_schools"].to_i == 1
  end

  def my_organizations?
    return false if params["my_organizations"].nil?

    params["my_organizations"].to_i == 1
  end

  def school_levels_edit_collection(project)
    return [] if project.schools.empty?

    collection = [["Toutes les classes", "all_levels"]]
    collection + project.schools.first&.school_levels&.map { |school_level| [school_level.full_name_without_school, school_level.id] }
  end

  def contractualized_companies_collection
    current_user.companies
      .select { |company| company.active_contract? && company.user_can_create_project?(current_user) }
      .map { |company| [company.full_name, company.id] }
  end

  def edit_project?
    params["action"] == "edit"
  end
end
