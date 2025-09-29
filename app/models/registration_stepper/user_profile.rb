module RegistrationStepper
  class UserProfile
    include ActiveModel::Model
    attr_accessor :first_name,
      :last_name,
      :email,
      :contact_email,
      :birthday,
      :role,
      :role_additional_information,
      :accept_privacy_policy,
      :accept_marketing,
      :user_schools_attributes,
      :user_company_attributes,
      :school_level_ids,
      :company_form

    validates :first_name, :last_name, presence: true
    validates :role, presence: true, inclusion: {in: User.roles.keys}
    validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
    validate :email_uniqueness
    validate :academic_email?, if: -> { role == "teacher" && email.present? }
    validate :birthday_is_a_date?, if: -> { birthday.present? }
    validate :user_is_more_than_13_years_old, if: -> { birthday.is_a?(Date) }
    validate :privacy_policy_accepted?, if: -> { accept_privacy_policy == "0" }

    def full_name
      "#{first_name} #{last_name}"
    end

    private

    def email_uniqueness
      errors.add(:email, "Cette adresse email est déjà utilisée") if User.find_by(email: email)
    end

    def academic_email?
      return if email.match?(/@(ac-aix-marseille|ac-amiens|ac-besancon|ac-bordeaux|ac-caen|ac-clermont|ac-creteil|ac-corse|ac-dijon|ac-grenoble|ac-guadeloupe|ac-guyane|ac-lille|ac-limoges|ac-lyon|ac-martinique|ac-mayotte|ac-montpellier|ac-nancy-metz|ac-nantes|ac-nice|ac-orleans-tours|ac-paris|ac-poitiers|ac-reims|ac-rennes|ac-reunion|ac-rouen|ac-strasbourg|ac-toulouse|ac-versailles)\.fr$/) || email.match?(/@education\.mc$/) || email.match?(/@lfmadrid\.org$/)

      errors.add(:email, "L'email doit être votre mail académique")
    end

    def birthday_is_a_date?
      return if birthday.is_a?(Date)

      errors.add(:birthday, "La date de naissance doit être une date")
    end

    def user_is_more_than_13_years_old
      return if birthday < 13.years.ago

      errors.add(:birthday, "Vous devez avoir plus de 13 ans pour vous inscrire")
    end

    def privacy_policy_accepted?
      errors.add(:accept_privacy_policy, "La politique de confidentialité doit être accepté") unless accept_privacy_policy == "1"
    end
  end
end
