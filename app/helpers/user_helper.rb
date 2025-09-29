module UserHelper
  def user_avatar_color(user)
    case user.role
    when "teacher"
      "primary-acc-2"
    when "tutor"
      "color-var-2"
    when "voluntary"
      "color-var-1"
    when "children"
      "color-var-5"
    end
  end
end
