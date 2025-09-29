ActiveAdmin.register SubSkill do
  menu parent: "Gestion des projets", label: proc { I18n.t("active_admin.sub_skills") }

  permit_params :skill_id, :name

  filter :skill, label: "Compétence", as: :select, collection: Skill.all.map { |skill| [skill.name.to_s, skill.id] }
  filter :name_cont, label: "Nom"

  index title: proc { I18n.t("active_admin.sub_skills") } do
    column :id
    column :name
    column :skill
    actions
  end

  show do
    attributes_table do
      row :skill
      row :name
    end
  end
end
