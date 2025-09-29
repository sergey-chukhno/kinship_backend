module RegistrationStepperHelper
  def display_navbar?
    request.fullpath.include?("/pupil") || request.fullpath.include?("users/edit")
  end

  def title_sign_up_stepper(role = nil)
    case role
    when "tutor"
      "Inscription parent"
    when "voluntary"
      "Inscription Volontaire"
    when "teacher"
      "Inscription enseignant"
    else
      "Inscription"
    end
  end

  def label_for_email(role = nil)
    return "Adresse email académique" if role == "teacher"

    "Adresse email"
  end

  def label_for_expend_skill_to_school(role = nil)
    return "Je souhaite partager mes compétences à l'ensemble de l'établissement" if role == "tutor"

    "Je souhaite proposer les compétences aux autres établissement de la ville"
  end

  def hint_for_email(role = nil)
    case role
    when "tutor"
      "Votre adresse email personnelle et pas celle de votre enfant"
    when "voluntary"
      "Votre adresse email personnelle"
    when "teacher"
      "Votre adresse email académique"
    else
      ""
    end
  end

  def title_for_fifth_step(role = nil)
    return "Je souhaite partager mes compétences avec la communauté éducative de mon établissement" if role == "teacher"
    return "Je souhaite partager mes compétences avec les organisations auxquelles je suis rattaché(e)" if role == "voluntary"

    "Je souhaite partager mes compétences personnelles avec la classe de mon (mes) enfant(s) ?"
  end

  def title_for_fourth_step(role = nil)
    return "Je suis disponible pour réaliser un atelier, aider un projet, accompagner une sortie" if role == "voluntary"

    "Je suis disponible pour accompagner une sortie scolaire avec la classe de mon (mes) enfant(s)"
  end

  def teacher_stepper?
    request.fullpath.include?("teacher")
  end

  def voluntary_stepper?
    request.fullpath.include?("voluntary")
  end

  def tutor_stepper?
    request.fullpath.include?("tutor")
  end

  def is_teacher?
    session[:user_role]["role"] == "teacher"
  end
end
