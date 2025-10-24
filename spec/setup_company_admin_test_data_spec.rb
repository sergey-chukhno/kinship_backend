require 'rails_helper'

RSpec.describe 'Company Admin Test Data Setup', type: :request do
  it 'creates comprehensive test data for Company Dashboard API testing' do
    puts "\n" + "="*80
    puts "Setting up Company Dashboard Test Data"
    puts "="*80 + "\n"
    
    # ========================================
    # 1. CREATE MAIN COMPANY
    # ========================================
    puts "\n📍 Creating Main Company..."
    
    main_company = create(:company,
      name: "TechCorp Industries",
      siret_number: "12345678901234",
      city: "Paris",
      zip_code: "75001",
      email: "contact@techcorp.com",
      website: "https://techcorp.com",
      referent_phone_number: "0123456789",
      description: "Leading technology and innovation company",
      status: :confirmed
    )
    puts "✅ Main Company: #{main_company.name} (ID: #{main_company.id})"
    
    # ========================================
    # 2. CREATE BRANCH COMPANY
    # ========================================
    puts "\n📍 Creating Branch Company..."
    
    branch_company = create(:company,
      name: "TechCorp Lyon",
      siret_number: "98765432109876",
      city: "Lyon",
      zip_code: "69001",
      email: "lyon@techcorp.com",
      referent_phone_number: "0198765432",
      description: "Lyon branch of TechCorp",
      status: :confirmed,
      parent_company: main_company
    )
    puts "✅ Branch Company: #{branch_company.name} (ID: #{branch_company.id})"
    
    # ========================================
    # 3. CREATE COMPANY ADMIN (SUPERADMIN)
    # ========================================
    puts "\n📍 Creating Company Admins..."
    
    # Find or create superadmin user
    company_admin = User.find_by(email: "admin@drakkar.io") || create(:user,
      email: "admin@drakkar.io",
      first_name: "Admin",
      last_name: "Drakkar",
      role: "tutor",
      confirmed_at: Time.current
    )
    puts "✅ Company Admin: #{company_admin.full_name} (ID: #{company_admin.id})"
    
    # Associate with main company as superadmin
    UserCompany.find_or_create_by!(
      user: company_admin,
      company: main_company
    ) do |uc|
      uc.role = :superadmin
      uc.status = :confirmed
    end
    puts "   → Associated as SUPERADMIN with #{main_company.name}"
    
    # Create a regular admin
    regular_admin = create(:user,
      email: "regular.admin@ac-paris.fr",
      first_name: "Regular",
      last_name: "Admin",
      role: "teacher",
      confirmed_at: Time.current
    )
    puts "✅ Regular Admin: #{regular_admin.full_name} (ID: #{regular_admin.id})"
    
    UserCompany.create!(
      user: regular_admin,
      company: main_company,
      role: :admin,
      status: :confirmed
    )
    puts "   → Associated as ADMIN with #{main_company.name}"
    
    # Create a referent
    referent_user = create(:user,
      email: "referent@ac-paris.fr",
      first_name: "Referent",
      last_name: "User",
      role: "teacher",
      confirmed_at: Time.current
    )
    puts "✅ Referent User: #{referent_user.full_name} (ID: #{referent_user.id})"
    
    UserCompany.create!(
      user: referent_user,
      company: main_company,
      role: :referent,
      status: :confirmed
    )
    puts "   → Associated as REFERENT with #{main_company.name}"
    
    # ========================================
    # 4. CREATE BRANCH COMPANY ADMIN
    # ========================================
    puts "\n📍 Creating Branch Company Admin..."
    
    branch_admin = create(:user,
      email: "branch.admin@ac-lyon.fr",
      first_name: "Branch",
      last_name: "Admin",
      role: "teacher",
      confirmed_at: Time.current
    )
    puts "✅ Branch Admin: #{branch_admin.full_name} (ID: #{branch_admin.id})"
    
    UserCompany.create!(
      user: branch_admin,
      company: branch_company,
      role: :superadmin,
      status: :confirmed
    )
    puts "   → Associated as SUPERADMIN with #{branch_company.name}"
    
    # ========================================
    # 5. CREATE CONTRACTS
    # ========================================
    puts "\n📍 Creating Contracts..."
    
    # Main company contract
    main_contract = Contract.create!(
      contractable: main_company,
      active: true,
      start_date: 1.year.ago,
      end_date: 1.year.from_now
    )
    puts "✅ Main Company Contract (ID: #{main_contract.id}, Active: #{main_contract.active})"
    
    # Branch company contract
    branch_contract = Contract.create!(
      contractable: branch_company,
      active: true,
      start_date: 6.months.ago,
      end_date: 6.months.from_now
    )
    puts "✅ Branch Company Contract (ID: #{branch_contract.id}, Active: #{branch_contract.active})"
    
    # ========================================
    # 6. CREATE TEST BADGE
    # ========================================
    puts "\n📍 Creating Test Badge..."
    
    test_badge = Badge.first || create(:badge,
      name: "Innovation Excellence",
      description: "Awarded for outstanding innovation",
      level: 1,
      series: "Série TouKouLeur"
    )
    puts "✅ Badge: #{test_badge.name} (Level: #{test_badge.level}, Series: #{test_badge.series})"
    
    # ========================================
    # 7. CREATE PROJECT
    # ========================================
    puts "\n📍 Creating Test Project..."
    
    test_project = create(:project,
      title: "Innovation Challenge 2025",
      description: "Annual innovation challenge for employees",
      owner: company_admin,
      start_date: Date.today,
      end_date: 3.months.from_now,
      status: :in_progress,
      private: false,
      companies: [main_company]
    )
    puts "✅ Project: #{test_project.title} (ID: #{test_project.id})"
    puts "   → Owner: #{test_project.owner.full_name}"
    puts "   → Companies: #{test_project.companies.map(&:name).join(', ')}"
    
    # ========================================
    # 8. CREATE PARTNER SCHOOL FOR PARTNERSHIP
    # ========================================
    puts "\n📍 Creating Partner School..."
    
    partner_school = create(:school,
      name: "Lycée Victor Hugo",
      city: "Paris",
      zip_code: "75015",
      school_type: "lycee",
      referent_phone_number: "0145678901",
      status: :confirmed
    )
    puts "✅ Partner School: #{partner_school.name} (ID: #{partner_school.id})"
    
    # ========================================
    # 9. CREATE PARTNERSHIP
    # ========================================
    puts "\n📍 Creating Test Partnership..."
    
    partnership = Partnership.create!(
      initiator: main_company,
      partnership_type: :bilateral,
      name: "Tech-Education Partnership",
      description: "Collaboration for student internships",
      status: :pending,
      share_members: false,
      share_projects: true,
      has_sponsorship: true
    )
    puts "✅ Partnership: #{partnership.name} (ID: #{partnership.id}, Type: #{partnership.partnership_type})"
    
    # Add main company as confirmed member
    PartnershipMember.create!(
      partnership: partnership,
      participant: main_company,
      role_in_partnership: :sponsor,
      member_status: :confirmed,
      confirmed_at: Time.current
    )
    puts "   → Main Company (sponsor, confirmed)"
    
    # Add partner school as pending member
    PartnershipMember.create!(
      partnership: partnership,
      participant: partner_school,
      role_in_partnership: :beneficiary,
      member_status: :pending
    )
    puts "   → Partner School (beneficiary, pending)"
    
    # ========================================
    # 10. SUMMARY
    # ========================================
    puts "\n" + "="*80
    puts "✅ TEST DATA SETUP COMPLETE"
    puts "="*80
    
    puts "\n📊 Summary:"
    puts "   Companies: #{Company.count} (Main: #{Company.main_companies.count}, Branches: #{Company.branch_companies.count})"
    puts "   Users: #{User.count}"
    puts "   Company Memberships: #{UserCompany.count}"
    puts "   Contracts: #{Contract.where(contractable_type: 'Company').count}"
    puts "   Projects: #{Project.count}"
    puts "   Partnerships: #{Partnership.count}"
    puts "   Badges: #{Badge.count}"
    
    puts "\n🔑 Login Credentials:"
    puts "   Email: admin@drakkar.io"
    puts "   Password: password"
    puts "   Company ID: #{main_company.id}"
    puts "   Role: superadmin"
    
    puts "\n🌐 Test Endpoints:"
    puts "   GET /api/v1/companies/#{main_company.id}"
    puts "   GET /api/v1/companies/#{main_company.id}/stats"
    puts "   GET /api/v1/companies/#{main_company.id}/members"
    puts "   GET /api/v1/companies/#{main_company.id}/projects"
    puts "   GET /api/v1/companies/#{main_company.id}/partnerships"
    puts "   GET /api/v1/companies/#{main_company.id}/branches"
    puts "\n"
  end
end

