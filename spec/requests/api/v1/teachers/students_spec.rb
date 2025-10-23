require 'swagger_helper'

RSpec.describe 'API V1 Teachers Students', type: :request do
  let(:teacher_user) { create(:user, :teacher, :confirmed) }
  let(:school) { create(:school, :confirmed, school_type: "college") }
  let(:school_level) { create(:school_level, school: school) }
  let!(:teacher_assignment) { create(:teacher_school_level, user: teacher_user, school_level: school_level, is_creator: true) }
  let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: teacher_user.id)}" }

  path '/api/v1/teachers/classes/{class_id}/students' do
    parameter name: :class_id, in: :path, type: :integer, description: 'Class ID'
    
    get 'List students in class' do
      tags 'Teacher Students'
      security [Bearer: []]
      produces 'application/json'
      
      parameter name: :search, in: :query, type: :string, required: false, description: 'Search by name'
      parameter name: :has_email, in: :query, type: :boolean, required: false, description: 'Filter by email status'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      
      response '200', 'students listed successfully' do
        let(:class_id) { school_level.id }
        let!(:student) { create(:user, :children, :confirmed) }
        let!(:user_school_level) { create(:user_school_level, user: student, school_level: school_level) }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']).to be_an(Array)
          expect(json['meta']).to include('total_count', 'active_accounts', 'pending_claims')
        end
      end
      
      response '403', 'forbidden - not your class' do
        let(:other_teacher) { create(:user, :teacher, :confirmed) }
        let(:other_class) { create(:school_level) }
        let!(:other_assignment) { create(:teacher_school_level, user: other_teacher, school_level: other_class, is_creator: true) }
        let(:class_id) { other_class.id }
        
        run_test!
      end
    end
    
    post 'Add student to class' do
      tags 'Teacher Students'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :student_data, in: :body, schema: {
        type: :object,
        properties: {
          student: {
            type: :object,
            properties: {
              first_name: { type: :string },
              last_name: { type: :string },
              email: { type: :string },
              birthday: { type: :string },
              role: { type: :string, enum: ['children', 'tutor', 'voluntary'] }
            },
            required: ['first_name', 'last_name', 'birthday', 'role']
          }
        }
      }
      
      response '201', 'student added with email' do
        let(:class_id) { school_level.id }
        let(:student_data) { 
          { 
            student: {
              first_name: 'Jean',
              last_name: 'Martin',
              email: 'jean.martin@example.com',
              birthday: '2010-03-12',
              role: 'children'
            }
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['full_name']).to eq('Jean Martin')
          expect(json['has_temporary_email']).to be false
          expect(json['account_status']).to eq('welcome_email_sent')
        end
      end
      
      response '201', 'student added without email (temp email)' do
        let(:class_id) { school_level.id }
        let(:student_data) { 
          { 
            student: {
              first_name: 'Marie',
              last_name: 'Dupont',
              email: nil,
              birthday: '2010-05-15',
              role: 'children'
            }
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['full_name']).to eq('Marie Dupont')
          expect(json['has_temporary_email']).to be true
          expect(json['account_status']).to eq('pending_claim')
          expect(json['claim_url']).to be_present
        end
      end
      
      response '201', 'tutor added without email' do
        let(:class_id) { school_level.id }
        let(:student_data) { 
          { 
            student: {
              first_name: 'Dr',
              last_name: 'Smith',
              email: nil,
              birthday: '1985-01-01',
              role: 'tutor'
            }
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['role']).to eq('tutor')
          expect(json['school_membership']['will_become_school_member']).to be false
          expect(json['school_membership']['will_stay_class_only']).to be true
        end
      end
      
      response '400', 'invalid role' do
        let(:class_id) { school_level.id }
        let(:student_data) { 
          { 
            student: {
              first_name: 'Test',
              last_name: 'User',
              email: 'test@example.com',
              birthday: '2010-01-01',
              role: 'invalid_role'
            }
          } 
        }
        
        run_test!
      end
      
      response '422', 'validation failed' do
        let(:class_id) { school_level.id }
        let(:student_data) { 
          { 
            student: {
              first_name: '',
              last_name: 'User',
              email: 'test@example.com',
              birthday: '2010-01-01',
              role: 'children'
            }
          } 
        }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/teachers/classes/{class_id}/students/{id}' do
    parameter name: :class_id, in: :path, type: :integer, description: 'Class ID'
    parameter name: :id, in: :path, type: :integer, description: 'Student ID'
    
    delete 'Remove student from class' do
      tags 'Teacher Students'
      security [Bearer: []]
      
      response '204', 'student removed successfully' do
        let(:class_id) { school_level.id }
        let(:student) { create(:user, :children, :confirmed) }
        let!(:user_school_level) { create(:user_school_level, user: student, school_level: school_level) }
        let(:id) { student.id }
        
        run_test!
      end
      
      response '403', 'forbidden - student not in your classes' do
        let(:class_id) { school_level.id }
        let(:other_student) { create(:user, :children, :confirmed) }
        let(:id) { other_student.id }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/teachers/students/{id}/regenerate-claim' do
    parameter name: :id, in: :path, type: :integer, description: 'Student ID'
    
    post 'Regenerate claim link' do
      tags 'Teacher Students'
      security [Bearer: []]
      produces 'application/json'
      
      response '200', 'claim link regenerated' do
        let(:student) { create(:user, :children, has_temporary_email: true, claim_token: 'old_token') }
        let!(:user_school_level) { create(:user_school_level, user: student, school_level: school_level) }
        let(:id) { student.id }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['claim_token']).to be_present
          expect(json['claim_url']).to be_present
          expect(json['claim_token']).not_to eq('old_token')
        end
      end
      
      response '400', 'student already has confirmed email' do
        let(:student) { create(:user, :children, has_temporary_email: false) }
        let!(:user_school_level) { create(:user_school_level, user: student, school_level: school_level) }
        let(:id) { student.id }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/teachers/students/{id}/update-email' do
    parameter name: :id, in: :path, type: :integer, description: 'Student ID'
    
    patch 'Update student email' do
      tags 'Teacher Students'
      security [Bearer: []]
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :email_data, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string }
        },
        required: ['email']
      }
      
      response '200', 'email updated successfully' do
        let(:student) { create(:user, :children, has_temporary_email: true, claim_token: 'token') }
        let!(:user_school_level) { create(:user_school_level, user: student, school_level: school_level) }
        let(:id) { student.id }
        let(:email_data) { { email: 'new.email@example.com' } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to include('Email updated')
        end
      end
      
      response '400', 'student already has confirmed email' do
        let(:student) { create(:user, :children, has_temporary_email: false) }
        let!(:user_school_level) { create(:user_school_level, user: student, school_level: school_level) }
        let(:id) { student.id }
        let(:email_data) { { email: 'new.email@example.com' } }
        
        run_test!
      end
    end
  end
end
