class AddPartnershipToProjects < ActiveRecord::Migration[7.1]
  def change
    add_reference :projects, :partnership, null: true, foreign_key: true, index: true
    
    say "Added partnership_id to projects table (nullable for backward compatibility)"
    say "All existing projects remain as regular projects (partnership_id: null)"
  end
end
