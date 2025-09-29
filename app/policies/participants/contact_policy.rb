class Participants::ContactPolicy < Participants::BasePolicy
  def new?
    create?
  end

  def create?
    true
  end
end
