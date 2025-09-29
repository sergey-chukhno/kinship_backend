class CompaniesController < ApplicationController
  before_action :authorize_user, only: %i[new create]

  def new
    @skills = Skill.officials
    @company = Company.new
  end

  def create
    @skills = Skill.officials
    @company = Company.new(company_params)

    if @company.save
      set_company_owner
      notify_admin_on_organization_creation_mailer(@company)
      redirect_to edit_account_network_path(current_user), notice: "Votre demande a bien été prise en compte."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def notify_admin_on_organization_creation_mailer(company)
    admins_emails = User.where(admin: true).pluck(:email)

    admins_emails.each do |admin_email|
      AdminMailer.notify_admin_on_organization_creation(organisation_type: "company", organisation_name: company.name, admin_email: admin_email).deliver_later
    end
  end

  def authorize_user
    authorize current_user, policy_class: CompaniesPolicy
  end

  def company_params
    params.require(:company).permit(
      :company_type_id,
      :zip_code,
      :city,
      :name,
      :website,
      :referent_phone_number,
      :description,
      :siret_number,
      :email,
      :skill_additional_information,
      :job,
      :take_trainee,
      :propose_workshop,
      :propose_summer_job,
      skill_ids: [],
      sub_skill_ids: []
    )
  end

  def set_company_owner
    UserCompany.create(user: current_user, company: @company, owner: true)
  end
end
