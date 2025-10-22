class MakeContractsPolymorphic < ActiveRecord::Migration[7.1]
  def up
    # Add polymorphic columns for contractable (School, Company, or IndependentTeacher)
    add_reference :contracts, :contractable, polymorphic: true, index: true
    
    # Migrate existing school contracts to polymorphic
    execute <<-SQL
      UPDATE contracts 
      SET contractable_type = 'School', contractable_id = school_id 
      WHERE school_id IS NOT NULL
    SQL
    
    # Migrate existing company contracts to polymorphic
    execute <<-SQL
      UPDATE contracts 
      SET contractable_type = 'Company', contractable_id = company_id 
      WHERE company_id IS NOT NULL
    SQL
    
    # Keep school_id and company_id columns for now (backward compatibility)
    # Can remove in future migration after verification
    
    puts "✅ Migrated #{Contract.where.not(school_id: nil).count} school contracts"
    puts "✅ Migrated #{Contract.where.not(company_id: nil).count} company contracts"
  end
  
  def down
    # Reverse migration - restore from polymorphic to specific columns
    execute <<-SQL
      UPDATE contracts 
      SET school_id = contractable_id 
      WHERE contractable_type = 'School'
    SQL
    
    execute <<-SQL
      UPDATE contracts 
      SET company_id = contractable_id 
      WHERE contractable_type = 'Company'
    SQL
    
    remove_reference :contracts, :contractable, polymorphic: true
  end
end
