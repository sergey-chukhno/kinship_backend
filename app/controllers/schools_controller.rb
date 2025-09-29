class SchoolsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index]
  before_action :authorize_user, only: %i[new create]

  def new
    @school = School.new
  end

  def create
    @school = School.new(school_params)

    if @school.save && @school.referent_phone_number.present?
      set_school_owner
      notify_admin_on_organization_creation_mailer(@school)
      redirect_to edit_account_school_path(current_user), notice: "Votre demande a bien été prise en compte."
    else
      @school.errors.add(:referent_phone_number, "Veuillez renseigner un numéro de téléphone valide.") if @school.referent_phone_number.blank?
      render :new, status: :unprocessable_entity
    end
  end

  private

  def notify_admin_on_organization_creation_mailer(school)
    admins_emails = User.where(admin: true).pluck(:email)

    admins_emails.each do |admin_email|
      AdminMailer.notify_admin_on_organization_creation(organisation_type: "school", organisation_name: school.name, admin_email: admin_email).deliver_later
    end
  end

  def authorize_user
    authorize current_user, policy_class: SchoolPolicy
  end

  def school_params
    params.require(:school).permit(:zip_code, :city, :name, :school_type, :referent_phone_number)
  end

  def set_school_owner
    UserSchool.create(user: current_user, school: @school, owner: true)
  end
end
