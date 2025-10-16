FactoryBot.define do
  factory :partnership do
    association :initiator, factory: :company
    status { :pending }
    partnership_type { :bilateral }
    share_members { false }
    share_projects { true }
    has_sponsorship { false }
    
    # Create a complete partnership with members
    after(:create) do |partnership, evaluator|
      # Only create members if they don't exist
      if partnership.partnership_members.empty?
        # Add initiator as member if it's the initiator
        if partnership.initiator
          create(:partnership_member,
                 partnership: partnership,
                 participant: partnership.initiator,
                 member_status: :confirmed,
                 role_in_partnership: :partner)
        end
      end
    end
    
    trait :with_school_and_company do
      after(:create) do |partnership|
        school = create(:school, :confirmed)
        company = partnership.initiator
        
        create(:partnership_member,
               partnership: partnership,
               participant: school,
               member_status: :pending,
               role_in_partnership: :partner)
      end
    end
    
    trait :with_two_companies do
      after(:create) do |partnership|
        company_b = create(:company, :confirmed)
        
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
        # Initiator school member already created in after(:create)
        school_b = create(:school, :confirmed)
        
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
        # Confirm all members
        partnership.partnership_members.update_all(member_status: :confirmed, confirmed_at: Time.current)
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
        # Add a third member for multilateral
        school = create(:school, :confirmed)
        create(:partnership_member,
               partnership: partnership,
               participant: school,
               member_status: :pending,
               role_in_partnership: :partner)
      end
    end
    
    trait :with_sponsorship do
      has_sponsorship { true }
      
      after(:create) do |partnership|
        # Change initiator to sponsor
        partnership.partnership_members
                  .find_by(participant: partnership.initiator)
                  &.update(role_in_partnership: :sponsor)
        
        # Add beneficiary
        company_b = create(:company, :confirmed)
        create(:partnership_member,
               partnership: partnership,
               participant: company_b,
               member_status: :pending,
               role_in_partnership: :beneficiary)
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
