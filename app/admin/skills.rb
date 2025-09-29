ActiveAdmin.register Skill do
  menu parent: "Gestion des projets", label: proc { I18n.t("active_admin.skills") }

  permit_params :name, :official, sub_skills_attributes: [:id, :name, :_destroy]

  filter :name_cont, label: "Nom"
  filter :official, label: "Officiel"

  index title: proc { I18n.t("active_admin.skills") } do
    column :name
    column :official
    column("Sous-compétences") do |skill|
      skill.sub_skills.map { |sub_skill| sub_skill.name }.join(", ")
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :official
    end

    panel "Sous-compétences" do
      table_for skill.sub_skills do
        column :name do |sub_skill|
          link_to sub_skill.name, admin_sub_skill_path(sub_skill)
        end
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :official
      f.inputs "Sous compétence" do
        f.has_many :sub_skills, heading: "", allow_destroy: true do |t|
          t.input :name, label: "Nom - sous compétence"
        end
      end
    end
    f.actions
  end
end
