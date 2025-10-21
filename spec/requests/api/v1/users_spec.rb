require 'swagger_helper'

RSpec.describe 'API V1 Users', type: :request do
  
  path '/api/v1/users/me' do
    patch 'Update current user profile' do
      tags 'Users'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      description 'Update current user profile information'
      
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              job: { type: :string },
              birthday: { type: :string, format: 'date' },
              contact_email: { type: :string, format: 'email' },
              take_trainee: { type: :boolean },
              propose_workshop: { type: :boolean },
              show_my_skills: { type: :boolean },
              skill_ids: { type: :array, items: { type: :integer } },
              sub_skill_ids: { type: :array, items: { type: :integer } }
            }
          }
        }
      }
      
      response '200', 'profile updated' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:user) { { user: { first_name: 'Updated' } } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['first_name']).to eq('Updated')
        end
      end
      
      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid-token' }
        let(:user) { { user: { first_name: 'Test' } } }
        run_test!
      end
    end
  end
  
  path '/api/v1/users/me/projects' do
    get 'Get my projects' do
      tags 'Users', 'Projects'
      security [Bearer: []]
      produces 'application/json'
      description 'Get projects owned by or participated in by current user (NOT all org projects)'
      
      parameter name: :status, in: :query, type: :string, required: false, 
                description: 'Filter by status', enum: ['pending', 'in_progress', 'finished']
      parameter name: :by_company, in: :query, type: :integer, required: false,
                description: 'Filter by company ID'
      parameter name: :by_school, in: :query, type: :integer, required: false,
                description: 'Filter by school ID'
      parameter name: :by_role, in: :query, type: :string, required: false,
                description: 'Filter by user role in project', enum: ['owner', 'co_owner', 'admin', 'member']
      parameter name: :start_date_from, in: :query, type: :string, required: false, format: 'date'
      parameter name: :start_date_to, in: :query, type: :string, required: false, format: 'date'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Default: 12'
      
      response '200', 'projects found' do
        schema type: :object,
          properties: {
            data: { type: :array },
            meta: {
              type: :object,
              properties: {
                current_page: { type: :integer },
                total_pages: { type: :integer },
                total_count: { type: :integer },
                per_page: { type: :integer }
              }
            }
          }
        
        let(:user_record) { create(:user, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let(:school_level) { create(:school_level, school: school) }
        let!(:project) { create(:project, owner: user_record, school_level_ids: [school_level.id]) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['meta']).to be_present
        end
      end
      
      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid-token' }
        run_test!
      end
    end
  end
  
  path '/api/v1/users/me/badges' do
    get 'Get my badges' do
      tags 'Users', 'Badges'
      security [Bearer: []]
      produces 'application/json'
      description 'Get badges received by current user with filtering'
      
      parameter name: :series, in: :query, type: :string, required: false, description: 'Filter by badge series'
      parameter name: :level, in: :query, type: :integer, required: false, description: 'Filter by badge level'
      parameter name: :organization_type, in: :query, type: :string, required: false, enum: ['School', 'Company']
      parameter name: :organization_id, in: :query, type: :integer, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Default: 12'
      
      response '200', 'badges found' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['meta']).to be_present
        end
      end
    end
  end
  
  path '/api/v1/users/me/organizations' do
    get 'Get my organizations' do
      tags 'Users', 'Organizations'
      security [Bearer: []]
      produces 'application/json'
      description 'Get schools and companies user is member of, with role and permissions'
      
      parameter name: :type, in: :query, type: :string, required: false, enum: ['School', 'Company']
      parameter name: :status, in: :query, type: :string, required: false, enum: ['pending', 'confirmed']
      parameter name: :role, in: :query, type: :string, required: false, 
                enum: ['member', 'intervenant', 'referent', 'admin', 'superadmin']
      
      response '200', 'organizations found' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_present
          expect(json['data']['schools']).to be_an(Array)
          expect(json['data']['companies']).to be_an(Array)
        end
      end
    end
  end
  
  path '/api/v1/users/me/network' do
    get 'Get my network' do
      tags 'Users', 'Network'
      security [Bearer: []]
      produces 'application/json'
      description 'Get users from my organizations (respects branch and partnership visibility rules)'
      
      parameter name: :organization_id, in: :query, type: :integer, required: false
      parameter name: :organization_type, in: :query, type: :string, required: false, enum: ['School', 'Company']
      parameter name: :role, in: :query, type: :string, required: false, 
                enum: ['teacher', 'tutor', 'voluntary', 'children']
      parameter name: :has_skills, in: :query, type: :string, required: false, 
                description: 'Comma-separated skill IDs'
      parameter name: :search, in: :query, type: :string, required: false,
                description: 'Search by name or email'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      
      response '200', 'network found' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['meta']).to be_present
        end
      end
    end
  end
  
  path '/api/v1/users/me/skills' do
    patch 'Update my skills' do
      tags 'Users', 'Skills'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :skills_data, in: :body, schema: {
        type: :object,
        properties: {
          skill_ids: { type: :array, items: { type: :integer } },
          sub_skill_ids: { type: :array, items: { type: :integer } }
        }
      }
      
      response '200', 'skills updated' do
        let(:user_record) { create(:user, :confirmed) }
        let(:skill) { create(:skill) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:skills_data) { { skill_ids: [skill.id] } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['skills']).to be_an(Array)
        end
      end
    end
  end
  
  path '/api/v1/users/me/availability' do
    patch 'Update my availability' do
      tags 'Users', 'Availability'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :availability_data, in: :body, schema: {
        type: :object,
        properties: {
          availability: {
            type: :object,
            properties: {
              monday: { type: :boolean },
              tuesday: { type: :boolean },
              wednesday: { type: :boolean },
              thursday: { type: :boolean },
              friday: { type: :boolean },
              other: { type: :boolean }
            }
          }
        }
      }
      
      response '200', 'availability updated' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:availability_data) { { availability: { monday: true, tuesday: false } } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['id']).to be_present
        end
      end
    end
  end
  
  path '/api/v1/users/me/avatar' do
    post 'Upload avatar' do
      tags 'Users', 'Avatar'
      security [Bearer: []]
      consumes 'multipart/form-data'
      produces 'application/json'
      description 'Upload user avatar (max 5MB, JPEG/PNG/GIF/WebP/SVG)'
      
      parameter name: :avatar, in: :formData, type: :file, required: true
      
      response '201', 'avatar uploaded' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:avatar) { fixture_file_upload('spec/support/assets/test-image.jpeg', 'image/jpeg') }
        
        run_test!
      end
    end
    
    delete 'Delete avatar' do
      tags 'Users', 'Avatar'
      security [Bearer: []]
      produces 'application/json'
      
      response '200', 'avatar deleted' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        before do
          user_record.avatar.attach(
            io: File.open(Rails.root.join('spec', 'support', 'assets', 'test-image.jpeg')),
            filename: 'test-image.jpeg',
            content_type: 'image/jpeg'
          )
        end
        
        run_test!
      end
      
      response '404', 'no avatar to delete' do
        let(:user_record) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test!
      end
    end
  end
end

