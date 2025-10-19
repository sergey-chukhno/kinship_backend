class AddBranchSupportToCompaniesAndSchools < ActiveRecord::Migration[7.1]
  def change
    # Add parent_company reference to companies (self-referential)
    add_reference :companies, :parent_company, 
                  null: true, 
                  foreign_key: {to_table: :companies}, 
                  index: true
    
    # Add member visibility control for companies
    add_column :companies, :share_members_with_branches, 
               :boolean, 
               default: false, 
               null: false
    
    # Add parent_school reference to schools (self-referential)
    add_reference :schools, :parent_school, 
                  null: true, 
                  foreign_key: {to_table: :schools}, 
                  index: true
    
    # Add member visibility control for schools
    add_column :schools, :share_members_with_branches, 
               :boolean, 
               default: false, 
               null: false
    
    say "Added branch support to companies and schools"
    say "- parent_company_id/parent_school_id: Self-referential for branch hierarchy"
    say "- share_members_with_branches: Controls member visibility (default: false)"
  end
end
