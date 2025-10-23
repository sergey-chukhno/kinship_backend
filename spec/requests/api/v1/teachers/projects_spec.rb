require 'swagger_helper'

RSpec.describe 'API V1 Teachers Projects', type: :request do
  let!(:teacher_user) { create(:user, :teacher, :confirmed) }
  let!(:school) { create(:school, :confirmed, school_type: "college") }
  let!(:school_level) { create(:school_level, school: school) }
  let!(:teacher_assignment) { create(:teacher_school_level, user: teacher_user, school_level: school_level, is_creator: true) }
  let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }

  path '/api/v1/teachers/projects' do
    get 'list teacher projects' do
      tags 'Teachers'
      description 'List all projects that the teacher can manage (created by them or assigned to their classes)'
      produces 'application/json'
      security [Bearer: []]
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :status, in: :query, type: :string, enum: ['coming', 'in_progress', 'ended'], required: false, description: 'Filter by project status'
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search in project title and description'

      response '200', 'projects listed successfully' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        
               before do
                 # Ensure school_level is created
                 school_level
                 
                 # Create a project owned by the teacher
                 @owned_project = build(:project, owner: teacher_user, title: 'My Own Project', 
                   start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
                 @owned_project.project_school_levels.build(school_level: school_level)
                 @owned_project.save!
                 
                 # Create a project for the teacher's class
                 @class_project = build(:project, title: 'Class Project', 
                   start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
                 @class_project.project_school_levels.build(school_level: school_level)
                 @class_project.save!
                 
                 # Create a project the teacher is not involved with
                 other_school_level = create(:school_level, school: school, name: "Other Class")
                 @other_project = build(:project, title: 'Other Project', 
                   start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
                 @other_project.project_school_levels.build(school_level: other_school_level)
                 @other_project.save!
               end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
          expect(data['data'].length).to eq(2) # Only owned and class projects
          expect(data['meta']).to include('current_page', 'total_pages', 'total_count', 'per_page')
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid_token' }
        run_test!
      end
    end

    post 'create project' do
      tags 'Teachers'
      description 'Create a new project for a class'
      produces 'application/json'
      consumes 'application/json'
      security [Bearer: []]
      
      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Science Fair Project' },
          description: { type: :string, example: 'A project about renewable energy' },
          school_level_ids: { type: :array, items: { type: :integer }, example: [1] },
          start_date: { type: :string, format: :date, example: '2024-01-01' },
          end_date: { type: :string, format: :date, example: '2024-12-31' },
          participants_number: { type: :integer, example: 5 },
          private: { type: :boolean, example: false },
          status: { type: :string, enum: ['coming', 'in_progress', 'ended'], example: 'in_progress' }
        },
        required: ['title', 'school_level_ids', 'start_date', 'end_date']
      }

      response '201', 'project created successfully' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:project) do
          {
            title: 'New Science Project',
            description: 'Exploring renewable energy sources',
            school_level_ids: [school_level.id],
            start_date: Date.current.to_s,
            end_date: (Date.current + 1.month).to_s,
            participants_number: 8,
            private: false,
            status: 'in_progress'
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('New Science Project')
          expect(data['school_levels']).to be_an(Array)
          expect(data['school_levels'].first['id']).to eq(school_level.id)
          expect(data['owner']['id']).to eq(teacher_user.id)
        end
      end

      response '422', 'validation failed' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:project) { { title: '' } }
        run_test!
      end

      response '403', 'forbidden - not authorized to create project for this class' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:other_school_level) { create(:school_level, school: school, name: "Other Class") }
        let(:project) { { title: 'Test Project', school_level_ids: [other_school_level.id] } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:project) { { title: 'Test Project', school_level_ids: [school_level.id] } }
        run_test!
      end
    end
  end

  path '/api/v1/teachers/projects/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Project ID'

    get 'show project' do
      tags 'Teachers'
      description 'Get project details'
      produces 'application/json'
      security [Bearer: []]

      response '200', 'project found' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:project) { 
          p = build(:project, owner: teacher_user, title: 'My Project', 
            start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: school_level)
          p.save!
          p
        }
        let(:id) { project.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('My Project')
          expect(data['owner']['id']).to eq(teacher_user.id)
        end
      end

      response '404', 'project not found' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:id) { 99999 }
        run_test!
      end

      response '403', 'forbidden - not authorized to view this project' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:other_school_level) { create(:school_level, school: school, name: "Other Class") }
        let(:other_project) { 
          p = build(:project, title: 'Other Project', 
            start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: other_school_level)
          p.save!
          p
        }
        let(:id) { other_project.id }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:id) { 1 }
        run_test!
      end
    end

    patch 'update project' do
      tags 'Teachers'
      description 'Update project details'
      produces 'application/json'
      consumes 'application/json'
      security [Bearer: []]
      
      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Updated Project Title' },
          description: { type: :string, example: 'Updated description' },
          participants_number: { type: :integer, example: 10 },
          private: { type: :boolean, example: true },
          status: { type: :string, enum: ['coming', 'in_progress', 'ended'], example: 'ended' }
        }
      }

      response '200', 'project updated successfully' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:project_record) { 
          p = build(:project, owner: teacher_user, title: 'Original Title', 
            start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: school_level)
          p.save!
          p
        }
        let(:id) { project_record.id }
        let(:project) do
          {
            title: 'Updated Title',
            description: 'Updated description',
            status: 'ended'
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('Updated Title')
          expect(data['status']).to eq('ended')
        end
      end

      response '422', 'validation failed' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:project_record) { 
          p = build(:project, owner: teacher_user, 
            start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: school_level)
          p.save!
          p
        }
        let(:id) { project_record.id }
        let(:project) { { title: '' } }
        run_test!
      end

      response '403', 'forbidden - not authorized to update this project' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:other_school_level) { create(:school_level, school: school, name: "Other Class") }
        let(:other_project) { 
          p = build(:project, title: 'Other Project', 
            start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: other_school_level)
          p.save!
          p
        }
        let(:id) { other_project.id }
        let(:project) { { title: 'Updated Title' } }
        run_test!
      end

      response '404', 'project not found' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:id) { 99999 }
        let(:project) { { title: 'Updated Title' } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:id) { 1 }
        let(:project) { { title: 'Updated Title' } }
        run_test!
      end
    end

    delete 'delete project' do
      tags 'Teachers'
      description 'Delete a project'
      security [Bearer: []]

      response '204', 'project deleted successfully' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:project_record) { 
          p = build(:project, owner: teacher_user, title: 'To Be Deleted', 
            start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: school_level)
          p.save!
          p
        }
        let(:id) { project_record.id }

        run_test! do |response|
          expect(Project.find_by(id: project_record.id)).to be_nil
        end
      end

      response '403', 'forbidden - not authorized to delete this project' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:other_school_level) { create(:school_level, school: school, name: "Other Class") }
        let(:other_project) { 
          p = build(:project, title: 'Other Project', 
            start_date: Date.current, end_date: Date.current + 1.month, description: 'Test project')
          p.project_school_levels.build(school_level: other_school_level)
          p.save!
          p
        }
        let(:id) { other_project.id }
        run_test!
      end

      response '404', 'project not found' do
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }
        let(:id) { 99999 }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid_token' }
        let(:id) { 1 }
        run_test!
      end
    end
  end
end
