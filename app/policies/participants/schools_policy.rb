class Participants::SchoolsPolicy < Participants::BasePolicy
  class Scope < Scope
    def resolve
      collection = User.none

      user.user_schools.confirmed.each do |user_school|
        collection = collection.or(
          scope.includes(:user_schools, :skills, :schools, :availability)
            .where.not(role: :children)
            .where.not(id: user.id)
            .where.not(admin: true)
            .where(user_schools: {school: user_school.school, status: :confirmed})
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
