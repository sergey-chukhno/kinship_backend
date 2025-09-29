# Preview all emails at http://localhost:3000/rails/mailers/user
class UserPreview < ActionMailer::Preview
  def reset_password_instructions
    UserMailer.reset_password_instructions(User.first)
  end
end
