require 'swagger_helper'

RSpec.describe 'API V1 Teachers Classes', type: :request do
  let(:teacher_user) { create(:user, :teacher, :confirmed) }
  let(:school) { create(:school, :confirmed, school_type: "college") }
  let(:school_level) { create(:school_level, school: school) }
  let!(:teacher_assignment) { create(:teacher_school_level, user: teacher_user, school_level: school_level, is_creator: true) }
  let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }

  path '/api/v1/teachers/classes' do
    get 'List teacher classes' do
      tags 'Teacher Classes'
      security [Bearer: []]
      produces 'application/json'
      
      parameter name: :school_id, in: :query, type: :integer, required: false, description: 'Filter by school'
      parameter name: :is_independent, in: :query, type: :boolean, required: false, description: 'Filter independent vs school-owned'
      parameter name: :level, in: :query, type: :string, required: false, description: 'Filter by level'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      
      response '200', 'classes listed successfully' do
        let!(:independent_class) { create(:school_level, school: nil) }
        let!(:independent_assignment) { create(:teacher_school_level, user: teacher_user, school_level: independent_class, is_creator: true) }
        let!(:school_class) { create(:school_level, school: school, name: "Mathématiques 4ème B") }
        let!(:school_assignment) { create(:teacher_school_level, user: teacher_user, school_level: school_class, is_creator: true) }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['meta']).to include('current_page', 'total_pages', 'total_count')
        end
      end
      
      response '401', 'unauthorized' do
        let(:Authorization) { nil }
        run_test!
      end
      
      response '403', 'forbidden for non-teacher' do
        let(:student_user) { create(:user, :children, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: student_user.id)}" }
        run_test!
      end
    end
    
    post 'Create independent class' do
      tags 'Teacher Classes'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :class_data, in: :body, schema: {
        type: :object,
        properties: {
          class: {
            type: :object,
            properties: {
              name: { type: :string },
              level: { type: :string },
              description: { type: :string }
            },
            required: ['name', 'level']
          }
        }
      }
      
      response '201', 'class created successfully' do
        let(:class_data) { 
          { 
            class: {
              name: 'Mathématiques 5ème A',
              level: 'cinquieme',
            }
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['name']).to eq('Mathématiques 5ème A')
          expect(json['is_independent']).to be true
          expect(json['is_creator']).to be true
        end
      end
      
      response '422', 'validation failed' do
        let(:class_data) { 
          { 
            class: {
              name: '',
              level: 'cinquieme'
            }
          } 
        }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/teachers/classes/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Class ID'
    
    get 'Get class details' do
      tags 'Teacher Classes'
      security [Bearer: []]
      produces 'application/json'
      
      response '200', 'class details retrieved' do
        let(:id) { school_level.id }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['id']).to eq(school_level.id)
          expect(json['name']).to eq(school_level.name)
        end
      end
      
      response '403', 'forbidden - not your class' do
        let(:other_teacher) { create(:user, :teacher, :confirmed) }
        let(:other_class) { create(:school_level) }
        let!(:other_assignment) { create(:teacher_school_level, user: other_teacher, school_level: other_class, is_creator: true) }
        let(:id) { other_class.id }
        
        run_test!
      end
    end
    
    patch 'Update class' do
      tags 'Teacher Classes'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :class_data, in: :body, schema: {
        type: :object,
        properties: {
          class: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string }
            }
          }
        }
      }
      
      response '200', 'class updated successfully' do
        let(:id) { school_level.id }
        let(:class_data) { 
          { 
            class: {
              name: 'Updated Class Name'
            }
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['name']).to eq('Updated Class Name')
        end
      end
    end
    
    delete 'Delete class' do
      tags 'Teacher Classes'
      security [Bearer: []]
      
      response '204', 'class deleted successfully' do
        let(:independent_class) { create(:school_level, school: nil) }
        let!(:independent_assignment) { create(:teacher_school_level, user: teacher_user, school_level: independent_class, is_creator: true) }
        let(:id) { independent_class.id }
        
        run_test!
      end
      
      response '403', 'forbidden - cannot delete school class' do
        let(:id) { school_level.id }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/teachers/classes/{id}/transfer' do
    parameter name: :id, in: :path, type: :integer, description: 'Class ID'
    
    patch 'Transfer class to school' do
      tags 'Teacher Classes'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :transfer_data, in: :body, schema: {
        type: :object,
        properties: {
          school_id: { type: :integer }
        },
        required: ['school_id']
      }
      
      response '200', 'class transferred successfully' do
        let(:independent_class) { create(:school_level, school: nil, name: "Independent Math Class") }
        let!(:independent_assignment) { create(:teacher_school_level, user: teacher_user, school_level: independent_class, is_creator: true) }
        let(:id) { independent_class.id }
        let!(:user_school) { create(:user_school, user: teacher_user, school: school, role: :intervenant) }
        let!(:confirm_user_school) { user_school.update!(status: :confirmed) }
        let(:transfer_data) { { school_id: school.id } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['school_id']).to eq(school.id)
          expect(json['is_independent']).to be false
        end
      end
      
      response '403', 'forbidden - not school member' do
        let(:independent_class) { create(:school_level, school: nil) }
        let!(:independent_assignment) { create(:teacher_school_level, user: teacher_user, school_level: independent_class, is_creator: true) }
        let(:id) { independent_class.id }
        let(:transfer_data) { { school_id: school.id } }
        
        run_test!
      end
    end
  end
end
