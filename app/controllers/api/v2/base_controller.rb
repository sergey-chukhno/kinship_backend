class Api::V2::BaseController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_api_access!
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  private

  def authenticate_api_access!
    @api_access = ApiAccess.find_by(token: params[:token])

    if @api_access.nil?
      render json: {error: "Invalid API token"}, status: :unauthorized
    end
  end
end
