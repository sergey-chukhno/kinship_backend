class Participants::CompaniesPolicy < Participants::BasePolicy
  class Scope < Scope
    def resolve
      collection = User.none

      user.user_company.confirmed.each do |user_company|
        collection = collection.or(
          scope.includes(:user_company, :skills, :companies, :availability)
            .where.not(id: user.id)
            .where.not(admin: true)
            .where(user_company: {company_id: user_company.company_id, status: :confirmed})
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
