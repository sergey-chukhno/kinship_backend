ActiveAdmin.register UserBadge do
  menu parent: "Gestion des badges", label: "Badges Attribués", priority: 7
  permit_params :status, :sender_id, :receiver_id, :badge_id, :project_id, :project_title, :project_description, :comment, user_badge_skills_attributes: %i[id badge_skill_id _destroy]
  filter :sender
  filter :receiver
  filter :badge
  filter :project
  filter :project_title
  filter :project_description
  filter :status

  scope I18n.t("activerecord.attributes.user_badge.statuses.pending"), :pending, default: true
  scope I18n.t("activerecord.attributes.user_badge.statuses.approved"), :approved
  scope I18n.t("activerecord.attributes.user_badge.statuses.rejected"), :rejected

  index do
    column :id
    column :sender
    column :receiver
    column :badge
    column :project
    column :project_title
    column :project_description
    tag_column :status, interactive: true do |badge|
      I18n.t("activerecord.attributes.user_badge.statuses.#{badge.status}")
    end
    column :documents do |badge|
      badge.documents.map { |document| link_to document.filename, rails_blob_path(document.blob, disposition: "preview"), target: "_blank" }.join("<br>").html_safe
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :sender
      row :receiver
      row :badge
      row :project
      row :project_title
      row :project_description
      tag_row :status, interactive: true do |badge|
        I18n.t("activerecord.attributes.user_badge.statuses.#{badge.status}")
      end
      row :comment
      row :documents do |badge|
        badge.documents.map { |document| link_to document.filename, rails_blob_path(document.blob, disposition: "preview"), target: "_blank" }.join("<br>").html_safe
      end
      row "Savoir-faire et compétences", :user_badge_skills do |badge|
        badge.user_badge_skills.map do |user_badge_skill|
          "#{user_badge_skill.badge_skill.name} (#{user_badge_skill.badge_skill.category})"
        end.join("<br>").html_safe
      end
    end
  end
end
