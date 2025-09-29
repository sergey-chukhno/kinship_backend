ActiveAdmin.register School do
  menu parent: "Gestion des établissements", label: "Etablissements", priority: 1

  permit_params :name, :zip_code, :school_type, :city, :status, :referent_phone_number,
    school_levels_attributes: [:id, :name, :level, :_destroy]

  filter :name, desciption: "Nom"
  filter :zip_code, label: "Code postal"
  filter :school_type, as: :select, collection: School.school_types, label: "Type d'établissement"
  filter :city, label: "Ville"
  filter :status, as: :select, collection: School.statuses, label: "Statut"

  index do
    column "Nom", :name
    column "Code postal", :zip_code
    column "Type d'établissement", :school_type
    column "Ville", :city
    tag_column "Statut", :status, interactive: true
    column "Numéro de téléphone du référent", :referent_phone_number
    column "Directeur" do |school|
      school.owner&.user
    end
    actions
  end

  show do
    attributes_table do
      row "Nom" do |school|
        school.name
      end
      row "Code postal" do |school|
        school.zip_code
      end
      row "Type d'établissement" do |school|
        school.school_type
      end
      row "Ville" do |school|
        school.city
      end
      tag_row :status, interactive: true
      row "Numéro de téléphone du référent" do |school|
        school.referent_phone_number
      end
      row "Directeur" do |school|
        school.owner&.user
      end
    end

    panel "Classes rattachées à l'établissement" do
      table_for school.school_levels do
        column "Niveau scolaire" do |school_level|
          school_level.full_name_without_school
        end
        column "Liens" do |school_level|
          (link_to "Voir", admin_school_level_path(school_level)) + " | " + (link_to "Modifier", edit_admin_school_level_path(school_level)) + " | " + (link_to "Supprimer", admin_school_level_path(school_level), method: :delete, data: {confirm: "Êtes-vous sûr de vouloir supprimer cette classe ?"})
        end
      end
      div do
        link_to "Ajouter une classe", new_admin_school_level_path(school_level: {school_id: school.id})
      end
    end

    panel "Contrats de l'établissement" do
      table_for school.contracts do
        toggle_bool_column "Actif", :active
        column "Début du contrat", :start_date, format: "%d/%m/%Y"
        column "Fin du contrat", :end_date, format: "%d/%m/%Y"
        column "Liens" do |contract|
          (link_to "Voir", admin_contract_path(contract)) + " | " + (link_to "Modifier", edit_admin_contract_path(contract)) + " | " + (link_to "Supprimer", admin_contract_path(contract), method: :delete, data: {confirm: "Êtes-vous sûr de vouloir supprimer ce contrat ?"})
        end
      end
      div do
        link_to "Ajouter un contrat", new_admin_contract_path(contract: {school_id: school.id})
      end
    end

    panel "Utilisateur rattaché à l'établissement" do
      table_for school.user_schools do
        column "Utilisateur" do |user_school|
          link_to user_school.user.full_name, admin_user_path(user_school.user)
        end
        tag_column "Statut", :status, interactive: true
        toggle_bool_column "Administrateur", :admin
        toggle_bool_column "Directeur", :owner
        column "Liens" do |user_school|
          (link_to "Voir", admin_user_school_path(user_school)) + " | " + (link_to "Modifier", edit_admin_user_school_path(user_school)) + " | " + (link_to "Supprimer", admin_user_school_path(user_school), method: :delete, data: {confirm: "Êtes-vous sûr de vouloir supprimer cet utilisateur ?"})
        end
      end
    end
  end

  form do |f|
    f.inputs "Information de l'établissement" do
      f.input :name, label: "Nom"
      f.input :city, label: "Ville"
      f.input :zip_code, label: "Code postal"
      f.input :school_type, label: "Type d'établissement"
      f.input :status, label: "Statut"
      f.input :referent_phone_number, label: "Numéro de téléphone du référent"
    end
    f.actions do
      f.action :submit
      f.cancel_link(:back)
    end
  end

  controller do
    def update
      @school = School.find(params[:id])
      @school_old_status = @school.status
      super

      OrganizationMailer.notify_organization_confirmation(organisation: @school, owner: @school.owner.user).deliver_later if @school.owner? && @school.status == "confirmed" && @school_old_status == "pending"
    end
  end
end
