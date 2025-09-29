ActiveAdmin.register Contract do
  menu label: "Contrats", priority: 3

  permit_params :school_id, :active, :start_date, :end_date, :company_id

  index do
    column "Partenaire" do |contract|
      contract.school.present? ? contract.school : contract.company
    end
    column "Type d'établissement" do |contract|
      contract.school.present? ? "Etablissement scolaire" : "Organisation"
    end
    toggle_bool_column :active
    column :start_date
    column :end_date
    actions
  end

  show do
    attributes_table do
      row :school
      row :active
      row :start_date
      row :end_date
    end
  end

  form do |f|
    f.inputs do
      f.input :school, hint: "Ne pas mettre d'école si vous renseignez une entreprise."
      f.input :company, hint: "Ne pas mettre d'entreprise si vous renseignez une école."
      f.input :active
      f.input :start_date, as: :date_time_picker
      f.input :end_date, as: :date_time_picker
    end
    f.actions do
      f.action :submit
      f.cancel_link(:back)
    end
  end

  controller do
    def create
      super do |success, faillure|
        id = params[:contract][:school_id].present? ? params[:contract][:school_id] : params[:contract][:company_id]
        contract_is_for_school = params[:contract][:school_id].present?

        success.html { contract_is_for_school ? redirect_to(admin_school_path(id)) : redirect_to(admin_company_path(id)) }
      end
    end

    def update
      super do |success, faillure|
        id = params[:contract][:school_id].present? ? params[:contract][:school_id] : params[:contract][:company_id]
        contract_is_for_school = params[:contract][:school_id].present?

        success.html { contract_is_for_school ? redirect_to(admin_school_path(id)) : redirect_to(admin_company_path(id)) }
      end
    end
  end
end
