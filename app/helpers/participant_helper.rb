module ParticipantHelper
  def all_registered_path?
    return false if only_association_path? || only_teacher_path? || only_tutor_path?

    true
  end

  def only_teacher_path?
    request.fullpath.include?("teachers=1")
  end

  def only_tutor_path?
    request.fullpath.include?("tutors=1")
  end

  def only_association_path?
    request.fullpath.include?("associations=1")
  end

  def skill_filter_checked?(skill_id)
    return false if params[skill_id.to_s].nil?

    params[skill_id.to_s].to_i == 1
  end

  def sub_skill_filter_checked?(sub_skill_id)
    return false if params[sub_skill_id.to_s].nil?

    params[sub_skill_id.to_s].to_i == 1
  end

  def availability_filter_checked?(availability)
    return false if params["by_#{availability}"].nil?

    params["by_#{availability}"].to_i == 1
  end

  def propose_workshop_filter_checked?
    return false if params["by_propose_workshop"].nil?

    params["by_propose_workshop"] == "true"
  end

  def not_propose_workshop_filter_checked?
    return false if params["not_by_propose_workshop"].nil?

    params["not_by_propose_workshop"] == "true"
  end

  def take_trainee_filter_checked?
    return false if params["by_take_trainee"].nil?

    params["by_take_trainee"] == "true"
  end

  def not_take_trainee_filter_checked?
    return false if params["not_by_take_trainee"].nil?

    params["not_by_take_trainee"] == "true"
  end
end

def info_message
  if current_user.tutor? || current_user.voluntary?
    "Ce compte Edu, vous permet de rechercher un stage. Pour accéder à toutes les fonctionnalités, il est nécessaire de se rattacher à une association de parents d'élèves ou de tout autre compte ayant souscrit à une offre Kinship."
  end
end

def empty_message
  return "Veillez à bien renseigner votre établissement dans votre profil afin de pouvoir accéder à cette fonctionnalité." if current_user.schools.empty?

  pending_schools_names = current_user.user_schools.pending.map { |user_school| user_school.school.full_name }.join(", ")
  return "Vos demande de rattachement pour les établissements suivants sont en attente de validation : #{pending_schools_names}" if current_user.user_schools.pending.count > 1
  return "Votre demande de rattachement pour l'établissement suivant est en attente de validation : #{pending_schools_names}" if current_user.user_schools.pending.count == 1

  "Aucun participant n'a été trouvé pour votre recherche." if @participants.empty?
end
