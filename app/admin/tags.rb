ActiveAdmin.register Tag do
  menu parent: "Gestion des projets"

  permit_params :name

  filter :name_cont, label: "Nom contient"

  index do
    column :name
    actions
  end
end
