ActiveAdmin.register Company do
  menu parent: "Gestion des organisations", label: "Organisation", priority: 1

  permit_params :name,
    :zip_code,
    :city,
    :company_type_id,
    :status,
    :referent_phone_number,
    :owner_id,
    :email,
    :siret_number,
    :skill_additional_information,
    :website,
    :job,
    :take_trainee,
    :propose_workshop,
    :propose_summer_job,
    company_skills_attributes: [:id, :skill_id, :_destroy],
    company_sub_skills_attributes: [:id, :sub_skill_id, :_destroy]

  filter :name_cont, label: "Nom contient"

  index do
    column "Nom", :name
    column "Code postal", :zip_code
    column "Ville", :city
    column "Type", :company_type
    tag_column :status, interactive: true
    column "Numéro de téléphone du référent", :referent_phone_number
    column "Directeur" do |company|
      company.owner&.user
    end
    actions
  end

  show do
    attributes_table do
      row "Nom" do |company|
        company.name
      end
      row "Code postal" do |company|
        company.zip_code
      end
      row "Ville" do |company|
        company.city
      end
      row "Type" do |company|
        company.company_type
      end
      tag_row :status, interactive: true
      row "Numéro de téléphone du référent" do |company|
        company.referent_phone_number
      end
      row "Directeur" do |company|
        company.owner&.user
      end
      row "Email" do |company|
        company.email
      end
      row "Site web" do |company|
        company.website
      end
      row "Numéro de SIRET" do |company|
        company.siret_number
      end
      row "Compétences - Informations complémentaires" do |company|
        company.skill_additional_information
      end
      row "Professions" do |company|
        company.job
      end
      row "Prendre des stagiaires" do |company|
        company.take_trainee
      end
      row "Proposer des ateliers" do |company|
        company.propose_workshop
      end
      row "Proposer des jobs d'été" do |company|
        company.propose_summer_job
      end
    end

    panel "Compétences de l'établissement" do
      table_for company.company_skills do
        column "Compétence" do |company_skill|
          link_to company_skill.skill.name, admin_skill_path(company_skill.skill)
        end
      end
    end

    panel "Sous-compétences de l'établissement" do
      table_for company.company_sub_skills do
        column "Sous-compétence" do |company_sub_skill|
          link_to company_sub_skill.sub_skill.name, admin_sub_skill_path(company_sub_skill.sub_skill)
        end
      end
    end

    panel "Contracts de l'établissement" do
      table_for company.contracts do
        toggle_bool_column :active
        column "Date de début", :start_date
        column "Date de fin", :end_date
        column "Liens" do |contract|
          (link_to "Voir", admin_contract_path(contract)) + " | " + (link_to "Modifier", edit_admin_contract_path(contract)) + " | " + (link_to "Supprimer", admin_contract_path(contract), method: :delete, data: {confirm: "Êtes-vous sûr de vouloir supprimer ce contrat ?"})
        end
      end
      div do
        link_to "Ajouter un contrat", new_admin_contract_path(contract: {company_id: company.id})
      end
    end

    panel "Utilisateurs rattaché à l'association" do
      table_for company.user_companies do
        column "Utilisateur" do |user_companie|
          link_to user_companie.user.full_name, admin_user_path(user_companie.user)
        end
        tag_column "Statut", :status, interactive: true
        toggle_bool_column "Administrateur", :admin
        toggle_bool_column "Directeur", :owner
      end
    end
  end

  form do |f|
    f.inputs "Information de l'association" do
      f.input :name, label: "Nom"
      f.input :zip_code, label: "Code postal"
      f.input :city, label: "Ville"
      f.input :company_type, label: "Type", as: :select, collection: CompanyType.all
      f.input :status, label: "Statut", as: :select, collection: Company.statuses.keys
      f.input :referent_phone_number, label: "Numéro de téléphone du référent"
      f.input :email, label: "Email"
      f.input :siret_number, label: "Numéro de SIRET"
      f.input :skill_additional_information, label: "Compétences - Informations complémentaires"
      f.input :website, label: "Site web"
      f.input :job, label: "Professions"
      f.input :take_trainee, label: "Prendre des stagiaires"
      f.input :propose_workshop, label: "Proposer des ateliers"
      f.input :propose_summer_job, label: "Proposer des jobs d'été"
      f.inputs "Compétences" do
        f.has_many :company_skills, heading: "", allow_destroy: true do |t|
          t.input :skill, label: "Compétence", as: :select, collection: Skill.all
        end
      end
      f.inputs "Sous-compétences" do
        f.has_many :company_sub_skills, heading: "", allow_destroy: true do |t|
          t.input :sub_skill, label: "Sous-compétence", as: :select, collection: SubSkill.all
        end
      end
    end
    f.actions do
      f.action :submit, label: "Enregistrer"
      f.cancel_link(:back, {label: "Annuler"})
    end
  end

  controller do
    def update
      @company = Company.find(params[:id])
      @company_old_status = @company.status
      super

      OrganizationMailer.notify_organization_confirmation(organisation: @company, owner: @company.owner.user).deliver_later if @company.owner? && @company_old_status == "pending" && @company.status == "confirmed"
    end
  end
end
