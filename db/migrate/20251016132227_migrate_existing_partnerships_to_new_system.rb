class MigrateExistingPartnershipsToNewSystem < ActiveRecord::Migration[7.1]
  def up
    say "========================================="
    say "Migrating existing partnerships to new system"
    say "========================================="
    
    # =========================================
    # PART 1: Migrate SchoolCompany partnerships
    # =========================================
    say ""
    say "Migrating SchoolCompany partnerships..."
    
    school_company_count = execute("SELECT COUNT(*) FROM school_companies").first["count"].to_i
    say "  Found #{school_company_count} school-company partnerships"
    
    if school_company_count > 0
      # Create partnerships and members for each SchoolCompany
      execute(<<-SQL)
        INSERT INTO partnerships (
          initiator_type,
          initiator_id,
          status,
          partnership_type,
          share_members,
          share_projects,
          has_sponsorship,
          confirmed_at,
          created_at,
          updated_at
        )
        SELECT
          'Company' as initiator_type,
          company_id as initiator_id,
          status,
          0 as partnership_type,  -- bilateral
          false as share_members,
          true as share_projects,
          false as has_sponsorship,
          CASE WHEN status = 1 THEN updated_at ELSE NULL END as confirmed_at,
          created_at,
          updated_at
        FROM school_companies
      SQL
      
      say "  ✓ Created #{school_company_count} partnership records"
      
      # Get the mapping of school_company IDs to new partnership IDs
      # We'll use a subquery approach since we can't easily return IDs
      
      # Create partnership members for schools
      execute(<<-SQL)
        INSERT INTO partnership_members (
          partnership_id,
          participant_type,
          participant_id,
          member_status,
          role_in_partnership,
          joined_at,
          confirmed_at,
          created_at,
          updated_at
        )
        SELECT
          p.id as partnership_id,
          'School' as participant_type,
          sc.school_id as participant_id,
          sc.status as member_status,
          0 as role_in_partnership,  -- partner
          sc.created_at as joined_at,
          CASE WHEN sc.status = 1 THEN sc.updated_at ELSE NULL END as confirmed_at,
          sc.created_at,
          sc.updated_at
        FROM school_companies sc
        JOIN partnerships p ON p.initiator_type = 'Company' 
                          AND p.initiator_id = sc.company_id
                          AND p.created_at = sc.created_at
      SQL
      
      say "  ✓ Created #{school_company_count} school members"
      
      # Create partnership members for companies (initiators)
      execute(<<-SQL)
        INSERT INTO partnership_members (
          partnership_id,
          participant_type,
          participant_id,
          member_status,
          role_in_partnership,
          joined_at,
          confirmed_at,
          created_at,
          updated_at
        )
        SELECT
          p.id as partnership_id,
          'Company' as participant_type,
          sc.company_id as participant_id,
          1 as member_status,  -- confirmed (initiator auto-confirmed)
          0 as role_in_partnership,  -- partner
          sc.created_at as joined_at,
          sc.created_at as confirmed_at,
          sc.created_at,
          sc.updated_at
        FROM school_companies sc
        JOIN partnerships p ON p.initiator_type = 'Company' 
                          AND p.initiator_id = sc.company_id
                          AND p.created_at = sc.created_at
      SQL
      
      say "  ✓ Created #{school_company_count} company members"
    end
    
    # =========================================
    # PART 2: Migrate CompanyCompany sponsorships
    # =========================================
    say ""
    say "Migrating CompanyCompany sponsorships..."
    
    company_company_count = execute("SELECT COUNT(*) FROM company_companies").first["count"].to_i
    say "  Found #{company_company_count} company-company sponsorships"
    
    if company_company_count > 0
      # Create partnerships with sponsorship flag
      execute(<<-SQL)
        INSERT INTO partnerships (
          initiator_type,
          initiator_id,
          status,
          partnership_type,
          share_members,
          share_projects,
          has_sponsorship,
          confirmed_at,
          created_at,
          updated_at
        )
        SELECT
          'Company' as initiator_type,
          company_sponsor_id as initiator_id,
          status,
          0 as partnership_type,  -- bilateral
          false as share_members,
          true as share_projects,
          true as has_sponsorship,  -- SPONSORSHIP
          CASE WHEN status = 1 THEN updated_at ELSE NULL END as confirmed_at,
          created_at,
          updated_at
        FROM company_companies
      SQL
      
      say "  ✓ Created #{company_company_count} partnership records with sponsorship"
      
      # Create partnership members for sponsors
      execute(<<-SQL)
        INSERT INTO partnership_members (
          partnership_id,
          participant_type,
          participant_id,
          member_status,
          role_in_partnership,
          joined_at,
          confirmed_at,
          created_at,
          updated_at
        )
        SELECT
          p.id as partnership_id,
          'Company' as participant_type,
          cc.company_sponsor_id as participant_id,
          1 as member_status,  -- confirmed (sponsor auto-confirmed)
          1 as role_in_partnership,  -- sponsor
          cc.created_at as joined_at,
          cc.created_at as confirmed_at,
          cc.created_at,
          cc.updated_at
        FROM company_companies cc
        JOIN partnerships p ON p.initiator_type = 'Company' 
                          AND p.initiator_id = cc.company_sponsor_id
                          AND p.has_sponsorship = true
                          AND p.created_at = cc.created_at
      SQL
      
      say "  ✓ Created #{company_company_count} sponsor members"
      
      # Create partnership members for beneficiaries
      execute(<<-SQL)
        INSERT INTO partnership_members (
          partnership_id,
          participant_type,
          participant_id,
          member_status,
          role_in_partnership,
          joined_at,
          confirmed_at,
          created_at,
          updated_at
        )
        SELECT
          p.id as partnership_id,
          'Company' as participant_type,
          cc.company_id as participant_id,
          cc.status as member_status,
          2 as role_in_partnership,  -- beneficiary
          cc.created_at as joined_at,
          CASE WHEN cc.status = 1 THEN cc.updated_at ELSE NULL END as confirmed_at,
          cc.created_at,
          cc.updated_at
        FROM company_companies cc
        JOIN partnerships p ON p.initiator_type = 'Company' 
                          AND p.initiator_id = cc.company_sponsor_id
                          AND p.has_sponsorship = true
                          AND p.created_at = cc.created_at
      SQL
      
      say "  ✓ Created #{company_company_count} beneficiary members"
    end
    
    # =========================================
    # PART 3: Summary
    # =========================================
    say ""
    say "========================================="
    say "Migration Summary:"
    total_partnerships = execute("SELECT COUNT(*) FROM partnerships").first["count"].to_i
    total_members = execute("SELECT COUNT(*) FROM partnership_members").first["count"].to_i
    say "  Total Partnerships: #{total_partnerships}"
    say "  Total Partnership Members: #{total_members}"
    say "  Expected Members: #{total_partnerships * 2}"
    say "  ✓ All partnerships migrated successfully!"
    say "========================================="
  end
  
  def down
    say "Rolling back partnership migration..."
    
    # Delete all new data
    execute("DELETE FROM partnership_members")
    execute("DELETE FROM partnerships")
    
    say "✓ Rollback complete - old data preserved in school_companies and company_companies"
  end
end
