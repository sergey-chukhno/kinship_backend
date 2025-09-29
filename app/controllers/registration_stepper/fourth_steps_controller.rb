module RegistrationStepper
  class FourthStepsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized, only: [:new, :create, :edit, :update]
    before_action :set_user, only: %i[new create edit update]
    layout "auth"

    def new
      @company = Company.new
    end

    def create
      @company = Company.new(company_params)
      if @company.save
        set_company_owner
        redirect_to edit_registration_stepper_fifth_step_path(id: @user, company_form: true)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(availability_params)
        redirect_to edit_registration_stepper_fifth_step_path(@user)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def availability_params
      params.require(:user).permit(availability_attributes: [:id, :monday, :tuesday, :wednesday, :thursday, :friday, :other])
    end

    def company_params
      params.require(:company).permit(:name, :description, :company_type_id, :zip_code, :city, :siret_number, :email, :website, :referent_phone_number)
    end

    def set_user
      @user = authorize User.find(params[:id]), policy_class: RegistrationStepper::FourthStepsPolicy
    end

    def set_company_owner
      UserCompany.create(user: @user, company: @company, owner: true)
    end
  end
end
