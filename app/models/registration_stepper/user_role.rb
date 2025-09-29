module RegistrationStepper
  class UserRole
    include ActiveModel::Model
    attr_accessor :role, :role_additional_information, :role_additional_information_other, :company_form

    PARENTS_ADDITIONAL_ROLES = ["parent", "grand-parent", "autres"].freeze
    VOLUNTARYS_ADDITIONAL_ROLES = ["lycéen ou étudiant", "salarié", "bénévole", "chargé(e) de mission", "autres"].freeze
    TEACHERS_ADDITIONAL_ROLES = ["professeur", "membre direction", "cpe", "autres"].freeze
    COMPANIES_ADDITIONAL_ROLES = ["Dirigeant ou chef d'entreprise", "Président(e) d’association, de fondation", "Responsable: recrutement, formation, RH...", "Autres"].freeze

    validates :role, presence: true, inclusion: {in: User.roles.keys}
    validates :role_additional_information, presence: {message: "Veuillez préciser votre fonction"}
  end
end
