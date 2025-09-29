ActiveAdmin.register Project do
  menu parent: "Gestion des projets", label: proc { I18n.t("active_admin.projects") }

  permit_params :title, :description, :start_date, :end_date, :owner_id, :main_picture, :status, :time_spent, :participants_number,
    project_tags_attributes: [:id, :tag_id, :_destroy],
    project_school_levels_attributes: [:id, :school_level_id, :_destroy],
    project_companies_attributes: [:id, :company_id, :_destroy],
    links_attributes: [:id, :name, :url, :_destroy],
    project_skills_attributes: [:id, :skill_id, :_destroy],
    keywords_attributes: [:id, :name, :_destroy],
    documents: [],
    pictures: [],
    teams_attributes: [:id, :title, :description, :_destroy]

  filter :title, label: "Titre"
  filter :tags, label: "Tags", as: :select, collection: Tag.all.map { |tag| [tag.name.to_s, tag.id] }
  filter :skills, label: "Compétences", as: :select, collection: Skill.all.map { |skill| [skill.name.to_s, skill.id] }
  filter :start_date, label: "Date de début"
  filter :end_date, label: "Date de fin"

  index title: proc { I18n.t("active_admin.projects") } do
    column :id
    column "Image du projet", :main_picture do |project|
      image_tag project.main_picture, width: 40, crop: :thumb if project.main_picture.attached?
    end
    column :title
    column :description
    column("Statut") { |project| I18n.t("activerecord.attributes.project.status.#{project.status}") }
    column :links
    column :start_date
    column :end_date
    column :owner
    actions
  end

  show do
    attributes_table do
      row :owner
      row("Statut") { |project| I18n.t("activerecord.attributes.project.status.#{project.status}") }
      row :time_spent
      row :participants_number
      row :school_levels
      row("Entreprises") { |project| project.companies.map(&:full_name).join(", ") }
      row :title
      row :skills
      row :tags
      row :description
      row :keywords
      row "Image du projet", :main_picture do |project|
        image_tag project.main_picture, width: 40, crop: :thumb if project.main_picture.attached?
      end
      row "Image supplémentaires", :pictures do |project|
        project.pictures.each { |picture| span image_tag(picture, width: 40) }
      end
      row :links
      row :documents do |project|
        project.documents.each do |document|
          span link_to document.filename, rails_blob_path(document, disposition: "attachment")
        end
      end
      row :start_date
      row :end_date
      row :teams
    end
  end

  form do |f|
    f.inputs do
      f.input :owner, as: :select, label: "Gérant", collection: User.all.map { |user| ["#{user.email} - #{user.first_name} #{user.last_name}", user.id] }
      f.input :status, as: :select, label: "Statut", collection: Project.statuses.keys.map { |status| [I18n.t("activerecord.attributes.project.status.#{status}"), status] }
      f.input :time_spent, label: "Temps passé"
      f.input :participants_number, label: "Nombre de participants"
    end

    f.inputs do
      f.input :title, label: "Titre"
      f.input :description, label: "Description"
      f.input :status, as: :select, label: "Statut", collection: Project.statuses.keys.map { |status| [I18n.t("activerecord.attributes.project.status.#{status}"), status] }
      f.input :start_date, as: :date_time_picker, label: "Date de début"
      f.input :end_date, as: :date_time_picker, label: "Date de fin"
    end

    f.inputs "Classes et niveaux associés" do
      f.has_many :project_school_levels, heading: "", allow_destroy: true do |t|
        t.input :school_level_id,
          label: false,
          as: :search_select,
          url: school_levels_path,
          display_name: "full_name",
          minimum_input_length: 1
      end
    end

    f.inputs "Entreprises" do
      f.has_many :project_companies, heading: "", allow_destroy: true do |t|
        t.input :company_id,
          label: false,
          as: :search_select,
          url: api_v1_companies_path,
          display_name: "full_name",
          minimum_input_length: 1
      end
    end

    f.inputs "Compétences" do
      f.has_many :project_skills, heading: "", allow_destroy: true do |t|
        t.input :skill, label: false, as: :select, collection: Skill.all.map { |skill| [skill.name.to_s, skill.id] }
      end
    end

    f.inputs "Tags" do
      f.has_many :project_tags, heading: "", allow_destroy: true do |t|
        t.input :tag, label: false, as: :select, collection: Tag.all.map { |tag| [tag.name.to_s, tag.id] }
      end
    end

    f.inputs "Mot-clés" do
      f.has_many :keywords, heading: "", allow_destroy: true, label: "Mot clé" do |t|
        t.input :name, label: false
      end
    end

    f.inputs "Liens" do
      f.has_many :links, heading: "", allow_destroy: true do |t|
        t.input :name, label: "Nom du lien"
        t.input :url, label: "URL du lien"
      end
    end

    f.inputs "Image principale" do
      f.input :main_picture, as: :file, label: false
      li "Image principale actuelle: " do
        f.object.main_picture.attached? ? span(image_tag(f.object.main_picture, width: 100)) : span("Aucune image principale")
      end
    end

    f.inputs "Images supplémentaires" do
      f.input :pictures, as: :file, label: false, input_html: {multiple: true}
      li "Images supplémentaires actuelles: " do
        f.object.pictures.attached? ? (f.object.pictures.each { |picture| span image_tag(picture, width: 100) }) : span("Aucune image supplémentaire")
      end
    end

    f.inputs "Documents" do
      f.input :documents, as: :file, label: false, input_html: {multiple: true}
      li "Documents actuels: " do
        if f.object.documents.attached?
          span f.object.documents.each { |document| link_to document.blob.filename, rails_blob_path(document, disposition: "attachment") }
        else
          span "Aucun document"
        end
      end
    end

    f.inputs "Equipes" do
      f.has_many :teams, heading: "", allow_destroy: true do |t|
        t.input :title, label: "Nom de l'équipe"
        t.input :description, label: "Description"
      end
    end

    f.actions
  end

  controller do
    def update
      delete_params_if_he_is_blank(:pictures)
      delete_params_if_he_is_blank(:documents)
      super
      resource.errors.full_messages.each do |message|
        flash[:error] = message
      end
    end
  end
end

private

def delete_params_if_he_is_blank(params_key)
  if params[:project][params_key].compact_blank.blank?
    params[:project].delete(params_key)
  end
end
