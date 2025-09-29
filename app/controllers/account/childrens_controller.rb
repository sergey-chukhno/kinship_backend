class Account::ChildrensController < ApplicationController
  before_action :set_children, only: %i[edit update destroy]
  before_action :set_schools_and_school_levels_collection, only: %i[new create edit update]
  layout "account"

  def index
    @childrens = policy_scope(User, policy_scope_class: Account::ChildrensPolicy::Scope)
  end

  def new
    authorize @children = User.new, policy_class: Account::ChildrensPolicy
  end

  def create
    authorize @children = User.new(children_params), policy_class: Account::ChildrensPolicy
    set_children_default_values(@children)

    if @children.save
      @total_childrens = current_user.childrens.count
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to account_childrens_path, notice: "Children was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @children.update(children_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to account_childrens_path, notice: "Children was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @children.destroy
    @total_childrens = current_user.childrens.count

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to account_childrens_path, notice: "Children was successfully destroyed." }
    end
  end

  def school_levels
    authorize @school_levels = SchoolLevel.where(school_id: params[:school_id]), policy_class: Account::ChildrensPolicy

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def children_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :school_ids,
      :school_level_ids,
      :show_my_skills,
      :company_ids
    )
  end

  def set_children
    authorize @children = User.find(params[:id]), policy_class: Account::ChildrensPolicy
  end

  def set_schools_and_school_levels_collection
    @schools_collection = current_user.schools
    @school_levels_collection = @children&.schools&.first&.school_levels || []
  end

  def set_children_default_values(children)
    children.role = "children"
    children.role_additional_information = "Enfant de #{current_user.first_name}"
    children.parent_id = current_user.id
    children.accept_privacy_policy = true
    children.email = current_user.email.gsub(/@/,
      "+#{children.first_name.strip.tr(" ",
        ".")}.#{children.last_name.strip.tr(" ",
          ".")}@")
    children.password = SecureRandom.hex(16)
    children.confirmed_at = Time.now
  end
end
