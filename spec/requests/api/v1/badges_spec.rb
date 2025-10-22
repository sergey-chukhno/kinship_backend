require 'swagger_helper'

RSpec.describe 'API V1 Badges', type: :request do
  
  path '/api/v1/badges/assign' do
    post 'Assign badge to users' do
      tags 'Badges'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      description 'Assign badge to one or more users (requires badge permission in organization)'
      
      parameter name: :badge_data, in: :body, schema: {
        type: :object,
        properties: {
          badge_assignment: {
            type: :object,
            properties: {
              badge_id: { type: :integer },
              recipient_ids: { type: :array, items: { type: :integer } },
              organization_id: { type: :integer },
              organization_type: { type: :string, enum: ['School', 'Company'] },
              project_title: { type: :string },
              project_description: { type: :string },
              badge_skill_ids: { type: :array, items: { type: :integer } }
            },
            required: ['badge_id', 'recipient_ids', 'organization_id', 'organization_type']
          }
        }
      }
      
      response '201', 'badges assigned' do
        let(:user_record) { create(:user, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let!(:superadmin_user) { create(:user, :confirmed) }
        let!(:superadmin_school) { create(:user_school, user: superadmin_user, school: school, role: :superadmin, status: :confirmed) }
        let!(:user_school) { create(:user_school, user: user_record, school: school, role: :admin, status: :confirmed) }
        let!(:contract) { create(:contract, school: school) }
        let(:badge) { create(:badge) }
        let(:recipient) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:badge_data) { 
          { 
            badge_assignment: {
              badge_id: badge.id,
              recipient_ids: [recipient.id],
              organization_id: school.id,
              organization_type: 'School',
              project_title: 'Great Achievement',
              project_description: 'Excellent work on the project'
            }
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['assigned_count']).to eq(1)
          expect(json['assignments']).to be_an(Array)
        end
      end
      
      response '403', 'forbidden - no permission' do
        let(:user_record) { create(:user, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let!(:user_school) { create(:user_school, user: user_record, school: school, role: :member, status: :confirmed) }
        let(:badge) { create(:badge) }
        let(:recipient) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:badge_data) { 
          { 
            badge_assignment: {
              badge_id: badge.id,
              recipient_ids: [recipient.id],
              organization_id: school.id,
              organization_type: 'School',
              project_title: 'Great Achievement',
              project_description: 'Excellent work on the project'
            }
          } 
        }
        
        run_test!
      end
      
      response '403', 'forbidden - no active contract' do
        let(:user_record) { create(:user, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let!(:user_school) { create(:user_school, user: user_record, school: school, role: :admin, status: :confirmed) }
        # No contract created - school.active_contract? returns false
        let(:badge) { create(:badge) }
        let(:recipient) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:badge_data) { 
          { 
            badge_assignment: {
              badge_id: badge.id,
              recipient_ids: [recipient.id],
              organization_id: school.id,
              organization_type: 'School',
              project_title: 'Great Achievement',
              project_description: 'Excellent work on the project'
            }
          } 
        }
        
        run_test!
      end
      
      response '201', 'badges assigned via independent teacher' do
        let(:teacher_user) { create(:user, :teacher, :confirmed) }
        let!(:independent_teacher) { create(:independent_teacher, user: teacher_user) }
        let!(:contract) { Contract.create!(contractable: independent_teacher, active: true, start_date: 1.month.ago, end_date: 1.year.from_now) }
        let(:badge) { create(:badge) }
        let(:recipient) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:badge_data) { 
          { 
            badge_assignment: {
              badge_id: badge.id,
              recipient_ids: [recipient.id],
              organization_id: independent_teacher.id,
              organization_type: 'IndependentTeacher',
              project_title: 'Independent Achievement',
              project_description: 'Great work in private tutoring'
            }
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['assigned_count']).to eq(1)
        end
      end
    end
  end
end

