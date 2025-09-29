ActiveAdmin.register Keyword do
  menu parent: "Gestion des projets", label: proc { I18n.t("active_admin.keywords") }

  permit_params :name

  filter :name_cont, label: "Nom contient"

  index title: proc { I18n.t("active_admin.keywords") } do
    column :name
    column :project
    actions
  end
end
