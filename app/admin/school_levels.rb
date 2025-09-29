ActiveAdmin.register SchoolLevel do
  menu parent: "Gestion des établissements", label: "Classes", priority: 2

  filter :school_id,
    label: "Nom de l'école",
    as: :search_select_filter,
    url: proc { api_v1_schools_path(admin: true) },
    minimum_input_length: 2,
    display_name: "full_name",
    collection: []
  filter :name_cont, label: "Nom de la classe", as: :string

  permit_params :name, :school_id, :level

  index title: proc { I18n.t("active_admin.school_levels") } do
    column :name
    column :level do |school_level|
      I18n.t("activerecord.attributes.school_level.levels.#{school_level.level}")
    end
    column :school
    actions
  end

  show do
    attributes_table do
      row :name
      row :level do |school_level|
        I18n.t("activerecord.attributes.school_level.levels.#{school_level.level}")
      end
      row :school
    end
  end

  form do |f|
    f.inputs do
      f.input :name, label: "Nom de la classe"
      f.input :level, label: "Niveau", as: :select, collection: SchoolLevel.levels.map { |level, value| [I18n.t("activerecord.attributes.school_level.levels.#{level}"), level] }
      f.input :school_id,
        label: "Ecole",
        as: :search_select,
        collection: [],
        url: api_v1_schools_path(admin: true),
        fields: [:name],
        display_name: "full_name",
        minimum_input_length: 2
    end
    f.actions do
      f.action :submit
      f.cancel_link(:back)
    end
  end

  controller do
    def create
      super do |success, faillure|
        success.html { redirect_to admin_school_path(params[:school_level][:school_id]) }
      end
    end

    def update
      super do |success, faillure|
        success.html { redirect_to admin_school_path(params[:school_level][:school_id]) }
      end
    end
  end
end
