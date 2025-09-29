ActiveAdmin.register User do
  menu priority: 1, label: proc { I18n.t("active_admin.users") }
  permit_params :email,
    :contact_email,
    :password,
    :password_confirmation,
    :first_name,
    :last_name,
    :birthday,
    :skill_additional_information,
    :role_additional_information,
    :expend_skill_to_school,
    :role,
    :job,
    :company_name,
    :take_trainee,
    :propose_workshop,
    :admin,
    :is_banned,
    :certify,
    :avatar,
    :parent_id,
    :accept_marketing,
    :accept_privacy_policy,
    :show_my_skills,
    user_skills_attributes: [:id, :skill_id, :_destroy],
    user_sub_skills_attributes: [:id, :sub_skill_id, :_destroy],
    availability_attributes: [:id, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :other],
    user_schools_attributes: [:id, :school_id, :_destroy],
    user_school_levels_attributes: [:id, :school_level_id, :_destroy]

  scope "Tous", :all, default: true
  scope "Professeurs", :teachers
  scope "Parents", :tutors
  scope "Voluntay", :voluntary
  scope "Enfants", :children

  filter :first_name_or_last_name_cont, label: "Prénom ou nom"
  filter :email, label: "Email"
  filter :user_schools_school_id,
    label: "Ecole",
    as: :search_select_filter,
    collection: [],
    url: proc { api_v1_schools_path(admin: true) },
    fields: [:name],
    display_name: "full_name",
    method_model: School,
    minimum_input_length: 2

  index do
    column :id
    column :avatar do |user|
      if user.avatar.attached?
        image_tag user.avatar, width: 40, crop: :thumb
      else
        image_tag "default-avatar.png", width: 40
      end
    end
    column :email do |user|
      user.email.present? ? user.email : "Pas d'email"
    end
    column :email_de_correspondance do |user|
      user.preferred_email
    end
    column :first_name
    column :last_name
    column :role do |user|
      I18n.t("activerecord.attributes.user.roles.#{user.role}")
    end
    column :school do |user|
      user.schools.map(&:full_name).join(", ")
    end
    column :certify?
    column :confirmed?
    column :is_banned?
    column :admin
    actions
  end

  show do
    attributes_table do
      row :avatar do |user|
        if user.avatar.attached?
          image_tag user.avatar, width: 40, crop: :thumb
        else
          image_tag "default-avatar.png", width: 40
        end
      end
      row :email, title: "Email"
      row :contact_email, title: "Email de contact" do |user|
        user.preferred_email
      end
      row :first_name
      row :last_name
      row :birthday
      row(:role) { |user| I18n.t("activerecord.attributes.user.roles.#{user.role}") }
      row(:role_additional_information) { |user| user.role_additional_information.nil? ? "" : user.role_additional_information }
      row :company_name, title: "Nom de l'entreprise"
      row :job
      row :take_trainee
      row :propose_workshop
      row :confirmed?
      row :certify?
      row :admin, title: "Admin"
      row :super_admin, title: "Super Admin"
      row :accept_marketing
      row :accept_privacy_policy
      row :is_banned
      row :skill_additional_information
      row :show_my_skills
      row :expend_skill_to_school
      row :parent do |user|
        link_to user.parent.full_name, admin_user_path(user.parent) if user.parent
      end
    end

    panel "Projets" do
      table_for user.projects do
        column do |project|
          link_to project.title, admin_project_path(project)
        end
      end
    end

    panel "Enfants" do
      table_for user.childrens do
        column do |child|
          link_to child.full_name, admin_user_path(child)
        end
      end
    end

    panel "Informations additionnelles" do
      table_for user.user_skills do
        column :competences do |user_skill|
          link_to user_skill.skill.name, admin_skill_path(user_skill.skill)
        end
      end

      table_for user.user_sub_skills do
        column :sous_competences do |user_sub_skill|
          link_to user_sub_skill.sub_skill.name, admin_sub_skill_path(user_sub_skill.sub_skill)
        end
        column :competence_associe do |user_sub_skill|
          link_to user_sub_skill.sub_skill.skill.name, admin_skill_path(user_sub_skill.sub_skill.skill)
        end
      end

      table_for user.schools do
        column :ecoles do |school|
          link_to school.full_name, admin_school_path(school)
        end
      end

      table_for user.school_levels do
        column :classes do |school_level|
          link_to "#{school_level.level_name} #{school_level.name} - #{school_level.school.full_name}", admin_school_level_path(school_level)
        end
      end

      unless user.teacher?
        table_for user.availability do
          column "Lundi" do |availability|
            availability.monday
          end
          column "Mardi" do |availability|
            availability.tuesday
          end
          column "Mercredi" do |availability|
            availability.wednesday
          end
          column "Jeudi" do |availability|
            availability.thursday
          end
          column "Vendredi" do |availability|
            availability.friday
          end
          column "Samedi" do |availability|
            availability.saturday
          end
          column "Dimanche" do |availability|
            availability.sunday
          end
          column "Autre" do |availability|
            availability.other
          end
        end
      end
    end
  end

  form do |f|
    inputs "Details" do
      input :email
      if resource.teacher?
        input :contact_email, hint: "Facultatif, laissez vide, si email de correspondance = email principal"
      end
      input :first_name
      input :last_name
      input :birthday, value: f.object.birthday&.strftime("%d/%m/%Y")
      input :role, label: "Role", as: :select, collection: User.roles.keys.map { |role| [I18n.t("activerecord.attributes.user.roles.#{role}"), role] }
      input :role_additional_information, label: "Information additonnel à propos du role"
      input :company_name, label: "Nom de l'entreprise"
      input :job, label: "Métier"
      input :accept_marketing, label: "Accepte le marketing"
      input :accept_privacy_policy, label: "Accepte la politique de confidentialité"
      input :take_trainee, label: "Prend des stagiaires"
      input :propose_workshop, label: "Propose des Ateliers"
      input :certify, label: "Certifié ?"
      input :admin, label: "Admin"
      input :is_banned
      input :parent_id, label: "Enfant de :", as: :select, collection: User.all.map { |tutor| [tutor.full_name, tutor.id] }
      input :skill_additional_information, label: "Information additonnel à propos des compétences"
      input :show_my_skills, label: "Montrer mes compétences"
      input :expend_skill_to_school, label: "Etendre les compétences à l'école"
      f.inputs "Compétences" do
        f.has_many :user_skills, heading: "", allow_destroy: true do |t|
          t.input :skill, label: false, as: :select, collection: Skill.all.map { |skill| [skill.name.to_s, skill.id] }
        end
      end

      f.inputs "Sous competences" do
        f.has_many :user_sub_skills, heading: "", allow_destroy: true do |t|
          t.input :sub_skill, label: false, as: :select, collection: SubSkill.all.map { |sub_skill| ["#{sub_skill.name} - Compétence: #{sub_skill.skill.name}", sub_skill.id] }
        end
      end

      f.inputs "Ecoles" do
        f.has_many :user_schools, heading: "", allow_destroy: true do |t|
          t.input :school_id,
            label: false,
            as: :search_select,
            collection: [],
            url: api_v1_schools_path(admin: true),
            fields: [:name],
            display_name: "full_name",
            minimum_input_length: 2
        end
      end

      f.inputs "Classes" do
        f.has_many :user_school_levels, heading: "", allow_destroy: true do |t|
          t.input :school_level_id,
            label: false,
            as: :search_select,
            collection: [],
            url: school_levels_path,
            display_name: "full_name",
            minimum_input_length: 1
        end
      end

      f.inputs "Disponibilités", for: :availability, allow_destroy: true do |t|
        t.input :monday, label: "Lundi"
        t.input :tuesday, label: "Mardi"
        t.input :wednesday, label: "Mercredi"
        t.input :thursday, label: "Jeudi"
        t.input :friday, label: "Vendredi"
        t.input :saturday, label: "Samedi"
        t.input :sunday, label: "Dimanche"
        t.input :other, label: "Autre"
      end
    end
    actions
  end

  controller do
    def create
      @user = User.new(permitted_params[:user])
      @user.email = nil if @user.parent_id.present?

      @user.password = "Kinship2023!" if @user.password.blank? && @user.parent_id.nil?
      if @user.save
        redirect_to admin_user_path(@user), notice: "Utilisateur créé"
      else
        render :new
      end
    end

    def update
      @user = User.find(params[:id])
      @user.assign_attributes(permitted_params[:user])
      @user.email = nil if @user.email == ""

      if @user.save
        redirect_to admin_user_path(@user), notice: "Utilisateur modifié"
      else
        flash[:notice] = @user.errors.full_messages.join(", ")
        render :edit
      end
    end
  end
end
