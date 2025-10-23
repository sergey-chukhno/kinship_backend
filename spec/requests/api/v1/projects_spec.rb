require 'swagger_helper'

RSpec.describe 'API V1 Projects', type: :request do
  
  path '/api/v1/projects' do
    get 'Get all available projects' do
      tags 'Projects'
      produces 'application/json'
      description 'Get all public projects and private projects from user organizations (if authenticated)'
      
      parameter name: :status, in: :query, type: :string, required: false, enum: ['pending', 'in_progress', 'finished']
      parameter name: :parcours, in: :query, type: :integer, required: false, description: 'Tag ID for parcours filter'
      parameter name: :start_date_from, in: :query, type: :string, required: false, format: 'date'
      parameter name: :start_date_to, in: :query, type: :string, required: false, format: 'date'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Default: 12'
      
      response '200', 'projects found' do
        let!(:school_level) { create(:school_level) }
        let!(:project) { 
          p = create(:project, private: false, start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.create!(school_level: school_level)
          p
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['meta']['per_page']).to eq(12)
        end
      end
    end
    
    post 'Create new project' do
      tags 'Projects'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      description 'Create new project (defaults: private=false, status=in_progress)'
      
      parameter name: :project_data, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              start_date: { type: :string, format: 'date' },
              end_date: { type: :string, format: 'date' },
              participants_number: { type: :integer },
              private: { type: :boolean },
              school_level_ids: { type: :array, items: { type: :integer } },
              skill_ids: { type: :array, items: { type: :integer } },
              tag_ids: { type: :array, items: { type: :integer } },
              company_ids: { type: :array, items: { type: :integer } }
            },
            required: ['title', 'description', 'start_date', 'end_date']
          }
        }
      }
      
      response '201', 'project created' do
        let(:user_record) { create(:user, :teacher, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let(:school_level) { create(:school_level, school: school) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:project_data) { 
          { 
            project: { 
              title: 'Test Project',
              description: 'Test',
              start_date: 1.week.from_now.to_date,
              end_date: 1.month.from_now.to_date,
              school_level_ids: [school_level.id]
            } 
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['title']).to eq('Test Project')
          expect(json['status']).to eq('in_progress')
          expect(json['private']).to eq(false)
        end
      end
      
      response '403', 'forbidden - no org permission' do
        let(:user_record) { create(:user, :confirmed, role: :tutor) }
        let(:school) { create(:school, school_type: :college) }
        let(:school_level) { create(:school_level, school: school) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:project_data) { 
          { 
            project: { 
              title: 'Test',
              description: 'Test',
              start_date: 1.week.from_now.to_date,
              end_date: 1.month.from_now.to_date,
              school_level_ids: [school_level.id]
            } 
          } 
        }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/projects/{id}' do
    parameter name: :id, in: :path, type: :integer
    
    get 'Get project details' do
      tags 'Projects'
      produces 'application/json'
      description 'Get single project with all associations'
      
      response '200', 'project found' do
        let!(:school_level) { create(:school_level) }
        let(:project) { 
          p = build(:project, private: false, start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: school_level)
          p.save!
          p
        }
        let(:id) { project.id }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['id']).to eq(project.id)
          expect(json['title']).to be_present
        end
      end
      
      response '404', 'project not found' do
        let(:id) { 99999 }
        run_test!
      end
    end
    
    patch 'Update project' do
      tags 'Projects'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :project_data, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              status: { type: :string, enum: ['pending', 'in_progress', 'finished'] }
            }
          }
        }
      }
      
      response '200', 'project updated' do
        let(:user_record) { create(:user, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let(:school_level) { create(:school_level, school: school) }
        let(:project) { create(:project, owner: user_record, school_level_ids: [school_level.id]) }
        let(:id) { project.id }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:project_data) { { project: { title: 'Updated Title' } } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['title']).to eq('Updated Title')
        end
      end
      
      response '403', 'forbidden - not owner' do
        let(:user_record) { create(:user, :confirmed) }
        let(:other_user) { create(:user, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let(:school_level) { create(:school_level, school: school) }
        let(:project) { create(:project, owner: other_user, school_level_ids: [school_level.id]) }
        let(:id) { project.id }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        let(:project_data) { { project: { title: 'Hacked' } } }
        
        run_test!
      end
    end
    
    delete 'Delete project' do
      tags 'Projects'
      security [Bearer: []]
      description 'Delete project (owner only)'
      
      response '204', 'project deleted' do
        let(:user_record) { create(:user, :confirmed) }
        let(:school) { create(:school, school_type: :college) }
        let(:school_level) { create(:school_level, school: school) }
        let(:project) { create(:project, owner: user_record, school_level_ids: [school_level.id]) }
        let(:id) { project.id }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/projects/{id}/join' do
    parameter name: :id, in: :path, type: :integer
    
    post 'Join project' do
      tags 'Projects'
      security [Bearer: []]
      produces 'application/json'
      description 'Request to join project (may require organization membership)'
      
      response '201', 'join request created' do
        let(:user_record) { create(:user, :confirmed) }
        let!(:school_level) { create(:school_level) }
        let(:project) { 
          p = build(:project, private: false, start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: school_level)
          p.save!
          p
        }
        let(:id) { project.id }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to include('join request created')
        end
      end
      
      response '409', 'already a member' do
        let(:user_record) { create(:user, :confirmed) }
        let!(:school_level) { create(:school_level) }
        let(:project) { 
          p = build(:project, private: false, start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: school_level)
          p.save!
          p
        }
        let!(:membership) { create(:project_member, user: user_record, project: project) }
        let(:id) { project.id }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user_record.id)}" }
        
        run_test!
      end
    end
  end
end

