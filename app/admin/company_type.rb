ActiveAdmin.register CompanyType do
  menu parent: "Gestion des organisations", label: "Type d'organisation", priority: 2

  permit_params :name
end
