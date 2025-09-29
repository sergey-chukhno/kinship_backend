class Participants::ProjectsPolicy < Participants::BasePolicy
  class Scope < Scope
    def resolve
      collection = User.none

      user.project_members.confirmed.each do |project_member|
        collection = collection.or(
          scope.includes(:project_members, :skills, :availability)
            .where.not(id: user.id)
            .where.not(admin: true)
            .where(project_members: {project: project_member.project, status: :confirmed})
        )
      end

      user.projects.select(&:owner).each do |project|
        collection = collection.or(
          scope.includes(:project_members, :skills, :availability)
            .where.not(id: user.id)
            .where.not(admin: true)
            .where(project_members: {project:, status: :confirmed})
        )
      end

      collection = collection.or(user.childrens)

      if user.teacher?
        collection.tutor.each do |tutor|
          collection = collection.or(tutor.childrens)
        end
      else
        collection.tutor.each do |tutor|
          collection = collection.or(tutor.childrens.where(show_my_skills: true))
        end
      end

      collection.order(certify: :desc, first_name: :asc, last_name: :asc)
    end
  end
end
