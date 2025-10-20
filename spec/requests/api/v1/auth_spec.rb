require 'swagger_helper'

RSpec.describe 'API V1 Authentication', type: :request do
  path '/api/v1/auth/login' do
    post 'User login' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      description 'Login with email and password, returns JWT token and user with available contexts for dashboard switching'
      
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@example.fr', description: 'User email address' },
          password: { type: :string, example: 'password123', description: 'User password' }
        },
        required: ['email', 'password']
      }
      
      response '200', 'successful login' do
        schema type: :object,
          properties: {
            token: { 
              type: :string, 
              description: 'JWT token valid for 24 hours',
              example: 'eyJhbGciOiJIUzI1NiJ9...'
            },
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                first_name: { type: :string },
                last_name: { type: :string },
                full_name: { type: :string },
                role: { 
                  type: :string, 
                  enum: ['teacher', 'tutor', 'voluntary', 'children'],
                  description: 'User role in system'
                },
                avatar_url: { type: :string, nullable: true },
                available_contexts: {
                  type: :object,
                  description: 'Available dashboards for context switching',
                  properties: {
                    user_dashboard: { type: :boolean },
                    teacher_dashboard: { type: :boolean },
                    schools: { 
                      type: :array,
                      items: {
                        type: :object,
                        properties: {
                          id: { type: :integer },
                          name: { type: :string },
                          role: { type: :string, enum: ['member', 'intervenant', 'referent', 'admin', 'superadmin'] },
                          permissions: { type: :object }
                        }
                      }
                    },
                    companies: { 
                      type: :array,
                      items: {
                        type: :object,
                        properties: {
                          id: { type: :integer },
                          name: { type: :string },
                          role: { type: :string, enum: ['member', 'intervenant', 'referent', 'admin', 'superadmin'] },
                          permissions: { type: :object }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          required: ['token', 'user']
        
        let(:user) { create(:user, :confirmed, password: 'password123') }
        let(:credentials) { { email: user.email, password: 'password123' } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['token']).to be_present
          expect(json['user']['id']).to eq(user.id)
          expect(json['user']['available_contexts']).to be_present
          expect(json['user']['available_contexts']['user_dashboard']).to eq(true)
        end
      end
      
      response '401', 'invalid credentials' do
        schema type: :object,
          properties: {
            error: { type: :string },
            message: { type: :string }
          }
        
        let(:credentials) { { email: 'wrong@example.fr', password: 'wrong' } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Invalid credentials')
        end
      end
      
      response '401', 'email not confirmed' do
        schema type: :object,
          properties: {
            error: { type: :string },
            message: { type: :string }
          }
        
        let(:user) { create(:user, password: 'password123', confirmed_at: nil) }
        let(:credentials) { { email: user.email, password: 'password123' } }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Email not confirmed')
        end
      end
    end
  end
  
  path '/api/v1/auth/me' do
    get 'Get current user' do
      tags 'Authentication'
      produces 'application/json'
      security [Bearer: []]
      description 'Get current authenticated user with full context, badges, skills, and availability information'
      
      response '200', 'successful' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            email: { type: :string },
            first_name: { type: :string },
            last_name: { type: :string },
            full_name: { type: :string },
            role: { type: :string, enum: ['teacher', 'tutor', 'voluntary', 'children'] },
            job: { type: :string, nullable: true },
            birthday: { type: :string, nullable: true },
            certify: { type: :boolean },
            admin: { type: :boolean },
            avatar_url: { type: :string, nullable: true },
            take_trainee: { type: :boolean },
            propose_workshop: { type: :boolean },
            show_my_skills: { type: :boolean },
            contact_email: { type: :string, nullable: true },
            confirmed_at: { type: :string, format: 'date-time' },
            available_contexts: { 
              type: :object,
              description: 'Available dashboards for this user'
            },
            skills: { type: :array },
            badges_received: { type: :array },
            availability: { type: :object, nullable: true }
          }
        
        let(:user) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['id']).to eq(user.id)
          expect(json['available_contexts']).to be_present
          expect(json['full_name']).to eq("#{user.first_name} #{user.last_name}")
        end
      end
      
      response '401', 'unauthorized' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        let(:Authorization) { 'Bearer invalid-token' }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Unauthorized')
        end
      end
    end
  end
  
  path '/api/v1/auth/refresh' do
    post 'Refresh JWT token' do
      tags 'Authentication'
      produces 'application/json'
      security [Bearer: []]
      description 'Refresh JWT token to extend expiration by 24 hours'
      
      response '200', 'token refreshed' do
        schema type: :object,
          properties: {
            token: { 
              type: :string,
              description: 'New JWT token valid for 24 hours'
            }
          },
          required: ['token']
        
        let(:user) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
        
        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['token']).to be_present
          
          # Verify new token is valid
          decoded = JsonWebToken.decode(json['token'])
          expect(decoded[:user_id]).to eq(user.id)
        end
      end
      
      response '401', 'unauthorized' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        let(:Authorization) { 'Bearer invalid-token' }
        
        run_test!
      end
    end
  end
  
  path '/api/v1/auth/logout' do
    delete 'User logout' do
      tags 'Authentication'
      security [Bearer: []]
      description 'Logout current user (client-side token removal, server responds with 204 No Content)'
      
      response '204', 'successful logout' do
        let(:user) { create(:user, :confirmed) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
        
        run_test!
      end
      
      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid-token' }
        
        run_test!
      end
    end
  end
end

