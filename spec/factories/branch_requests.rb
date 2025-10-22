FactoryBot.define do
  factory :branch_request do
    # Default: Company-Company branch request
    association :parent, factory: :company
    association :child, factory: :company
    association :initiator, factory: :company  # By default, parent initiates
    status { :pending }
    
    # Ensure initiator is either parent or child
    after(:build) do |branch_request|
      branch_request.initiator = branch_request.parent if branch_request.initiator.nil?
    end
    
    trait :pending do
      status { :pending }
    end
    
    trait :confirmed do
      status { :confirmed }
      confirmed_at { Time.current }
      
      # When confirmed, set the parent-child relationship
      after(:create) do |branch_request|
        if branch_request.child_type == 'Company'
          branch_request.child.update_column(:parent_company_id, branch_request.parent_id)
        elsif branch_request.child_type == 'School'
          branch_request.child.update_column(:parent_school_id, branch_request.parent_id)
        end
      end
    end
    
    trait :rejected do
      status { :rejected }
    end
    
    trait :initiated_by_parent do
      after(:build) do |branch_request|
        branch_request.initiator = branch_request.parent
      end
    end
    
    trait :initiated_by_child do
      after(:build) do |branch_request|
        branch_request.initiator = branch_request.child
      end
    end
    
    trait :for_schools do
      association :parent, factory: :school
      association :child, factory: :school
      
      after(:build) do |branch_request|
        branch_request.initiator = branch_request.parent
      end
    end
    
    trait :with_message do
      message { "Nous souhaitons créer une relation de filiale pour mieux collaborer." }
    end
  end
end
