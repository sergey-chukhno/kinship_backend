class RegistrationStepper::FourthStepsPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    user == record && user.voluntary?
  end

  def edit?
    user == record || !user.teacher?
  end

  def update?
    edit?
  end
end
