ActiveAdmin.register Badge do
  menu parent: "Gestion des badges", label: "Badges", priority: 6

  permit_params :name, :description, :level, :icon, badge_skills_attributes: %i[id name category _destroy]
  filter :name
  filter :description
  filter :level

  index do
    column :id
    column :icon do |badge|
      image_tag badge.icon, width: 48, height: 48 if badge.icon.attached?
    end
    column :name
    column :description
    column :level do |badge|
      I18n.t("activerecord.attributes.badge.levels.#{badge.level}")
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :description
      row :level do |badge|
        I18n.t("activerecord.attributes.badge.levels.#{badge.level}")
      end
      row :icon do |badge|
        image_tag badge.icon, width: 48, height: 48 if badge.icon.attached?
      end
    end

    panel "Domaines" do
      table_for badge.badge_skills.domain do
        column :name
      end
    end

    panel "Savoirs faire" do
      table_for badge.badge_skills.expertise do
        column :name
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :description, as: :text
      f.input :level
      f.input :icon, as: :file
      li "Icône actuelle : " do
        f.object.icon.attached? ? ul(image_tag(f.object.icon, width: 48, height: 48)) : ul("Aucune icône")
      end
    end

    f.inputs "Compétences" do
      f.has_many :badge_skills, allow_destroy: true do |c|
        c.input :category, as: :select, collection: BadgeSkill.categories.keys.map { |category|
                                                      [I18n.t("activerecord.attributes.badge_skill.categories.#{category}"), category]
                                                    }
        c.input :name
      end
      f.actions
    end
  end
end
