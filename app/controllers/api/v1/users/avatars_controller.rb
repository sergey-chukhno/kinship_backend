# Avatars API controller for User Dashboard
# Handles user avatar upload and deletion
class Api::V1::Users::AvatarsController < Api::V1::BaseController
  
  # POST /api/v1/users/me/avatar
  # Upload user avatar
  def create
    if params[:avatar].blank?
      return render json: {
        error: 'Bad Request',
        message: 'Avatar file is required'
      }, status: :bad_request
    end
    
    if current_user.avatar.attach(params[:avatar])
      render json: { 
        avatar_url: Rails.application.routes.url_helpers.rails_blob_url(
          current_user.avatar, 
          only_path: false
        ),
        message: 'Avatar uploaded successfully'
      }, status: :created
    else
      render json: { 
        error: 'Upload failed',
        message: 'Invalid file or file too large (max 5MB). Allowed types: JPEG, PNG, GIF, WebP, SVG'
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/users/me/avatar
  # Delete user avatar
  def destroy
    if current_user.avatar.attached?
      current_user.avatar.purge
      render json: { message: 'Avatar deleted successfully' }, status: :ok
    else
      render json: {
        error: 'Not Found',
        message: 'No avatar to delete'
      }, status: :not_found
    end
  end
end

