ActiveAdmin.register Team do
  menu parent: "Gestion des projets", label: proc { I18n.t("active_admin.teams") }, priority: 3

  permit_params :title, :description, :project_id, team_members_attributes: [:id, :user_id, :_destroy]

  filter :title_cont, label: "Nom contient"
  filter :project, label: "Projet"

  index title: proc { I18n.t("active_admin.teams") } do
    selectable_column
    column :title
    column :description
    column :project
    column(:participants) { |team| team.team_members.count }
    actions
  end

  show do
    attributes_table do
      row :title
      row :description
      row :project
    end

    panel "Membres de l'équipe" do
      table_for team.team_members do
        column("Membre") { |team_member| team_member.user.full_name }
        column("Rejoins le") { |team_member| team_member.created_at }
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :description
      f.input :project

      f.has_many :team_members, allow_destroy: true, heading: "Membres de l'équipe", new_record: "Ajouter un membre" do |team_member|
        team_member.input :user, as: :select, collection: User.participants_for_tutor(current_user).map { |user| [user.full_name, user.id] }
      end
    end
    f.actions
  end
end
