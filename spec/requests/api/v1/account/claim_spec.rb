require 'swagger_helper'

RSpec.describe 'API V1 Account Claim', type: :request do
  let(:teacher_user) { create(:user, :teacher, :confirmed) }
  let(:school) { create(:school, :confirmed, school_type: "college") }
  let(:school_level) { create(:school_level, school: school) }
  let!(:teacher_assignment) { create(:teacher_school_level, user: teacher_user, school_level: school_level, is_creator: true) }
  let(:student) { create(:user, :children, has_temporary_email: true, claim_token: 'test_token_123', birthday: Date.new(2010, 5, 15)) }
  let!(:user_school_level) { create(:user_school_level, user: student, school_level: school_level) }

  path '/api/v1/account/claim/info' do
    get 'Get claim information' do
      tags 'Account Claim'
      produces 'application/json'
      
      parameter name: :token, in: :query, type: :string, required: true, description: 'Claim token'
      
      response '200', 'claim info retrieved successfully' do
        let(:token) { 'test_token_123' }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['student']['full_name']).to eq(student.full_name)
          expect(json['class']['name']).to eq(school_level.name)
          expect(json['teacher']['full_name']).to eq(teacher_user.full_name)
          expect(json['school']['name']).to eq(school.name)
        end
      end
      
      response '404', 'invalid or expired token' do
        let(:token) { 'invalid_token' }
        
        run_test!
      end
      
      response '400', 'token required' do
        let(:token) { nil }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/account/claim' do
    post 'Claim account with real email and password' do
      tags 'Account Claim'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :claim_data, in: :body, schema: {
        type: :object,
        properties: {
          claim_token: { type: :string },
          email: { type: :string },
          password: { type: :string },
          password_confirmation: { type: :string },
          birthday: { type: :string }
        },
        required: ['claim_token', 'email', 'password', 'password_confirmation', 'birthday']
      }
      
      response '200', 'account claimed successfully' do
        let(:claim_data) { 
          { 
            claim_token: 'test_token_123',
            email: 'student.real@example.com',
            password: 'SecurePass123!',
            password_confirmation: 'SecurePass123!',
            birthday: '2010-05-15'
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Account claimed successfully!')
          expect(json['email']).to eq('student.real@example.com')
          expect(json['confirmation_required']).to be true
        end
      end
      
      response '422', 'birthday verification failed' do
        let(:claim_data) { 
          { 
            claim_token: 'test_token_123',
            email: 'student.real@example.com',
            password: 'SecurePass123!',
            password_confirmation: 'SecurePass123!',
            birthday: '2010-05-16'  # Wrong birthday
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Birthday verification failed')
        end
      end
      
      response '422', 'password confirmation mismatch' do
        let(:claim_data) { 
          { 
            claim_token: 'test_token_123',
            email: 'student.real@example.com',
            password: 'SecurePass123!',
            password_confirmation: 'DifferentPass123!',
            birthday: '2010-05-15'
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Validation Failed')
        end
      end
      
      response '422', 'password too weak' do
        let(:claim_data) { 
          { 
            claim_token: 'test_token_123',
            email: 'student.real@example.com',
            password: 'weak',
            password_confirmation: 'weak',
            birthday: '2010-05-15'
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Validation Failed')
        end
      end
      
      response '404', 'invalid or expired token' do
        let(:claim_data) { 
          { 
            claim_token: 'invalid_token',
            email: 'student.real@example.com',
            password: 'SecurePass123!',
            password_confirmation: 'SecurePass123!',
            birthday: '2010-05-15'
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Not Found')
        end
      end
      
      response '400', 'missing required fields' do
        let(:claim_data) { 
          { 
            claim_token: 'test_token_123',
            email: 'student.real@example.com'
            # Missing password, password_confirmation, birthday
          } 
        }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Bad Request')
        end
      end
    end
  end
end
