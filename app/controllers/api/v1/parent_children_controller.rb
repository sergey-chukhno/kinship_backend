# Parent Children API controller
# CRUD operations for parent's children information
# Authorization: Only parent_user can access their own children info
class Api::V1::ParentChildrenController < Api::V1::BaseController
  before_action :set_parent_child_info, only: [:show, :update, :destroy]
  before_action :authorize_parent_child_info, only: [:show, :update, :destroy]
  
  # GET /api/v1/parent_children
  # List all children info for current user (parent)
  # @return [JSON] Array of parent child info objects
  def index
    @parent_children = current_user.parent_child_infos.order(created_at: :desc)
    
    render json: {
      data: @parent_children.map { |child| serialize_parent_child_info(child) }
    }
  end
  
  # POST /api/v1/parent_children
  # Create new child info
  # @param first_name [String] Child's first name
  # @param last_name [String] Child's last name
  # @param birthday [Date] Child's birthday
  # @param school_id [Integer] Optional school ID
  # @param school_name [String] Optional school name
  # @param class_id [Integer] Optional school level ID
  # @param class_name [String] Optional class name
  # @return [JSON] Created parent child info object
  def create
    @parent_child_info = current_user.parent_child_infos.build(parent_child_info_params)
    
    if @parent_child_info.save
      render json: {
        message: 'Child information added successfully',
        data: serialize_parent_child_info(@parent_child_info)
      }, status: :created
    else
      render json: {
        error: 'Validation Failed',
        details: @parent_child_info.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/parent_children/:id
  # Get single child info
  # @return [JSON] Parent child info object
  def show
    render json: {
      data: serialize_parent_child_info(@parent_child_info)
    }
  end
  
  # PATCH /api/v1/parent_children/:id
  # Update child info
  # @param first_name [String] Child's first name
  # @param last_name [String] Child's last name
  # @param birthday [Date] Child's birthday
  # @param school_id [Integer] Optional school ID
  # @param school_name [String] Optional school name
  # @param class_id [Integer] Optional school level ID
  # @param class_name [String] Optional class name
  # @return [JSON] Updated parent child info object
  def update
    if @parent_child_info.update(parent_child_info_params)
      render json: {
        message: 'Child information updated successfully',
        data: serialize_parent_child_info(@parent_child_info)
      }
    else
      render json: {
        error: 'Validation Failed',
        details: @parent_child_info.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/parent_children/:id
  # Delete child info
  # @return [JSON] Success message
  def destroy
    @parent_child_info.destroy
    render json: {
      message: 'Child information deleted successfully'
    }, status: :ok
  end
  
  private
  
  def set_parent_child_info
    @parent_child_info = ParentChildInfo.find_by(id: params[:id])
    
    unless @parent_child_info
      render json: {
        error: 'Not Found',
        message: 'Child information not found'
      }, status: :not_found
    end
  end
  
  def authorize_parent_child_info
    unless @parent_child_info.parent_user_id == current_user.id
      render json: {
        error: 'Forbidden',
        message: 'You can only access your own children information'
      }, status: :forbidden
    end
  end
  
  def parent_child_info_params
    params.require(:parent_child_info).permit(
      :first_name, :last_name, :birthday,
      :school_id, :school_name, :class_id, :class_name
    )
  end
  
  def serialize_parent_child_info(child_info)
    {
      id: child_info.id,
      first_name: child_info.first_name,
      last_name: child_info.last_name,
      full_name: child_info.full_name,
      birthday: child_info.birthday,
      school_id: child_info.school_id,
      school_name: child_info.school_name,
      school: child_info.school ? {
        id: child_info.school.id,
        name: child_info.school.name,
        city: child_info.school.city,
        zip_code: child_info.school.zip_code
      } : nil,
      class_id: child_info.class_id,
      class_name: child_info.class_name,
      school_level: child_info.school_level ? {
        id: child_info.school_level.id,
        name: child_info.school_level.name
      } : nil,
      linked_user_id: child_info.linked_user_id,
      linked: child_info.linked?,
      created_at: child_info.created_at,
      updated_at: child_info.updated_at
    }
  end
end

