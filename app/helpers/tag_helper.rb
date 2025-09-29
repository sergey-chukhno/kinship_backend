module TagHelper
  def color_for_project_tag(tag)
    case tag
    when "Santé"
      "green"
    when "Citoyen"
      "pink"
    when "EAC"
      "purple"
    when "Créativité"
      "blue"
    when "Avenir"
      "yellow"
    when "Autre"
      "light-grey"
    else
      "grey"
    end
  end

  def color_for_user_role(role)
    case role
    when "teacher"
      "yellow"
    when "tutor"
      "purple"
    when "voluntary"
      "blue"
    else
      "grey"
    end
  end
end
