module EditingHelper
  def title_editing(role = nil)
    case role
    when "tutor"
      "Modifier mon profil Parent"
    when "voluntary"
      "Modifier mon profil Elève / Volontaire"
    when "teacher"
      "Modification mon profil Enseignant"
    end
  end

  def define_role_collection(role = nil)
    case role
    when "tutor"
      RegistrationStepper::UserRole::PARENTS_ADDITIONAL_ROLES
    when "voluntary"
      RegistrationStepper::UserRole::VOLUNTARYS_ADDITIONAL_ROLES
    when "teacher"
      RegistrationStepper::UserRole::TEACHERS_ADDITIONAL_ROLES
    else
      ["Aucun role"]
    end
  end

  def define_role_selected(current_user)
    return "autres" unless define_role_collection(current_user.role).include?(current_user.role_additional_information)

    current_user.role_additional_information
  end
end
