FactoryBot.define do
  factory :partnership do
    association :initiator, factory: :company
    status { :pending }
    partnership_type { :bilateral }
    share_members { false }
    share_projects { true }
    has_sponsorship { false }
    
    # By default, don't auto-create members
    # Use traits to create complete partnerships
    
    trait :with_school_and_company do
      after(:create) do |partnership|
        school = create(:school, :confirmed)
        company = partnership.initiator
        
        # Add initiator
        create(:partnership_member,
               partnership: partnership,
               participant: company,
               member_status: :confirmed,
               role_in_partnership: :partner)
        
        # Add school
        create(:partnership_member,
               partnership: partnership,
               participant: school,
               member_status: :pending,
               role_in_partnership: :partner)
      end
    end
    
    trait :with_two_companies do
      after(:create) do |partnership|
        company_a = partnership.initiator
        company_b = create(:company, :confirmed)
        
        # Add initiator
        create(:partnership_member,
               partnership: partnership,
               participant: company_a,
               member_status: :confirmed,
               role_in_partnership: :partner)
        
        # Add second company
        create(:partnership_member,
               partnership: partnership,
               participant: company_b,
               member_status: :pending,
               role_in_partnership: :partner)
      end
    end
    
    trait :with_two_schools do
      association :initiator, factory: :school
      
      after(:create) do |partnership|
        school_a = partnership.initiator
        school_b = create(:school, :confirmed)
        
        # Add initiator
        create(:partnership_member,
               partnership: partnership,
               participant: school_a,
               member_status: :confirmed,
               role_in_partnership: :partner)
        
        # Add second school
        create(:partnership_member,
               partnership: partnership,
               participant: school_b,
               member_status: :pending,
               role_in_partnership: :partner)
      end
    end
    
    trait :confirmed do
      status { :confirmed }
      confirmed_at { Time.current }
      
      after(:create) do |partnership|
        # Reload to get members created by other traits
        partnership.reload
        
        if partnership.partnership_members.any?
          # Confirm all existing members
          partnership.partnership_members.update_all(member_status: :confirmed, confirmed_at: Time.current)
        else
          # Create basic bilateral partnership if no members exist
          company_a = partnership.initiator
          company_b = create(:company, :confirmed)
          
          create(:partnership_member, partnership: partnership, participant: company_a, member_status: :confirmed, confirmed_at: Time.current, role_in_partnership: :partner)
          create(:partnership_member, partnership: partnership, participant: company_b, member_status: :confirmed, confirmed_at: Time.current, role_in_partnership: :partner)
        end
      end
    end
    
    trait :rejected do
      status { :rejected }
    end
    
    trait :multilateral do
      partnership_type { :multilateral }
      name { "Alliance Éducative #{rand(1000)}" }
      description { "Partenariat multilateral pour l'innovation pédagogique" }
      
      after(:create) do |partnership|
        company_a = partnership.initiator
        company_b = create(:company, :confirmed)
        school = create(:school, :confirmed)
        
        # Add all three members
        create(:partnership_member, partnership: partnership, participant: company_a, member_status: :confirmed, role_in_partnership: :partner)
        create(:partnership_member, partnership: partnership, participant: company_b, member_status: :pending, role_in_partnership: :partner)
        create(:partnership_member, partnership: partnership, participant: school, member_status: :pending, role_in_partnership: :partner)
      end
    end
    
    trait :with_sponsorship do
      has_sponsorship { true }
      
      after(:create) do |partnership|
        # Only create members if none exist
        if partnership.partnership_members.empty?
          sponsor = partnership.initiator
          company_b = create(:company, :confirmed)
          
          # Add sponsor
          create(:partnership_member,
                 partnership: partnership,
                 participant: sponsor,
                 member_status: :confirmed,
                 role_in_partnership: :sponsor)
          
          # Add beneficiary
          create(:partnership_member,
                 partnership: partnership,
                 participant: company_b,
                 member_status: :pending,
                 role_in_partnership: :beneficiary)
        else
          # Update existing members to have sponsorship roles
          partnership.partnership_members.first.update(role_in_partnership: :sponsor)
          partnership.partnership_members.second&.update(role_in_partnership: :beneficiary)
        end
      end
    end
    
    trait :sharing_members do
      share_members { true }
    end
    
    trait :not_sharing_projects do
      share_projects { false }
    end
  end
end
