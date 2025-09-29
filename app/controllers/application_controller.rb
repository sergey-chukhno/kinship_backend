class ApplicationController < ActionController::Base
  before_action :authenticate_user!, :redirect_for_banned_users, :register_logging_info,
    :redirect_for_not_confirmed_user

  include Pundit::Authorization

  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?
  after_action :alert_user_not_confirmed

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé.e à effectuer cette action."
    redirect_to(root_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name role job take_trainee])
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def redirect_for_banned_users
    return unless user_signed_in?
    return if request.fullpath.include?("/registration_stepper") || request.fullpath.include?("/banned_information")
    return if devise_controller?

    raise SecurityError if current_user.is_banned
  end

  rescue_from SecurityError do |_exception|
    redirect_to(banned_information_url)
  end

  def register_logging_info
    return unless Rails.env.production?

    logging_params = {
      ip_address: request.remote_ip,
      request_path: request.path,
      request_path_params: JSON.parse(params.to_json),
      request_code: response.status,
      request_time: DateTime.now,
      user_agent: request.user_agent,
      user_id: current_user&.id,
      user_email: current_user&.email
    }

    Logging.create(logging_params)
  end

  def redirect_for_not_confirmed_user
    return unless current_user
    return redirect_to root_path if current_user.confirmed? && request.fullpath.include?("/registration_stepper")

    redirect_to_waiting_for_confirmation_if_not_confirmed unless current_user.confirmed?
  end

  def alert_user_not_confirmed
    return unless current_user
    return if current_user.confirmed?

    flash[:alert] = "Votre compte n'est pas encore confirmé. Veuillez vérifier vos emails."
  end

  private

  def redirect_to_waiting_for_confirmation_if_not_confirmed
    return if request.fullpath.include?("/registration_stepper")
    return if request.fullpath.include?("/auth/confirmation/new")
    return if request.fullpath.include?("/banned_information")
    return if request.fullpath.include?("/auth/confirmation")

    redirect_to(registration_stepper_pending_confirmation_path)
  end
end
