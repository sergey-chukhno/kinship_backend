module SchoolFilterHelper
  def set_selected_school
    if params["search"] == "no"
      ""
    elsif params["by_school"].blank?
      return unless current_user.schools.any?

      current_user.schools.first.id
    else
      params["by_school"]["school_id"]
    end
  end
end
