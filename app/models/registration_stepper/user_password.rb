module RegistrationStepper
  class UserPassword
    include ActiveModel::Model
    attr_accessor :password, :password_confirmation

    validates :password, presence: true, length: {minimum: 6}
    validates :password_confirmation, presence: true
    validate :passwords_match

    def passwords_match
      errors.add(:password_confirmation, "Les mots de passe ne correspondent pas") if password != password_confirmation
    end
  end
end
