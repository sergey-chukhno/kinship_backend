class Account::BadgesPolicy < ApplicationPolicy
  attr_reader :user, :record, :token

  def initialize(user_context, record)
    @user = user_context[:user]
    @token = user_context[:token]
    @record = record
  end

  def tree?
    return true if user.present? && record == user
    return true if record.parent.present? && record.parent == user
    return true if user.present? && user.admin?
    return true if record.badges_token.present? && record.badges_token == token

    false
  end

  def level?
    true
  end

  def download?
    true
  end
end
