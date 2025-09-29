ActiveAdmin.register ApiAccess do
  menu label: "Gestion des clées d'API"

  permit_params :name, company_api_accesses_attributes: %i[id company_id _destroy]

  index do
    column :id
    column "Nom", :name
    column "Clé d'API", :token
    column "Organisations accessibles", :companies do |api_access|
      api_access.companies.each do |company|
        link_to company.name, admin_company_path(company)
      end
    end
    actions
  end

  show do
    attributes_table do
      row "Nom" do |api_access|
        api_access.name
      end
      row "Clé d'API" do |api_access|
        api_access.token
      end
      row "Organisations accessibles" do |api_access|
        api_access.companies.each do |company|
          link_to company.name, admin_company_path(company)
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.has_many :company_api_accesses, heading: "Organisations accessible par l'API", allow_destroy: true do |c|
        c.input :company, label: "Organisations", as: :select, collection: Company.all.map { |company| ["#{company.name} | (#{company.city} #{company.zip_code})", company.id] }
      end
      f.submit
    end
  end
end
