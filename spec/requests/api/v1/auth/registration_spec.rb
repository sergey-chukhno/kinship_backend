require 'rails_helper'

RSpec.describe 'API V1 Registration', type: :request do
  describe 'POST /api/v1/auth/register' do
    describe 'personal_user registration' do
      let(:valid_params) do
        {
          registration_type: 'personal_user',
          user: {
            email: "parent#{SecureRandom.hex(4)}@example.com",
            password: 'Password123!',
            password_confirmation: 'Password123!',
            first_name: 'John',
            last_name: 'Doe',
            birthday: '1990-01-01',
            role: 'parent',
            accept_privacy_policy: true
          }
        }
      end

      context 'with valid data' do
        it 'creates user successfully' do
          post '/api/v1/auth/register', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['message']).to include('successful')
          expect(json['email']).to eq(valid_params[:user][:email])
          expect(json['requires_confirmation']).to be true
          
          user = User.find_by(email: valid_params[:user][:email])
          expect(user).to be_present
          expect(user.confirmed?).to be false
        end

        it 'creates ParentChildInfo when children_info provided' do
          params_with_children = valid_params.deep_merge(
            children_info: [
              {
                first_name: 'Alice',
                last_name: 'Doe',
                birthday: '2010-05-15'
              }
            ]
          )
          
          post '/api/v1/auth/register', params: params_with_children.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:created)
          user = User.find_by(email: valid_params[:user][:email])
          expect(user.parent_child_infos.count).to eq(1)
          expect(user.parent_child_infos.first.first_name).to eq('Alice')
        end
      end

      context 'with invalid data' do
        it 'returns error for invalid email' do
          params = valid_params.deep_merge(user: { email: 'invalid_email' })
          post '/api/v1/auth/register', params: params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Validation failed')
          expect(json['errors']).to be_present
        end

        it 'returns error for academic email with personal user' do
          params = valid_params.deep_merge(user: { email: 'user@ac-nantes.fr' })
          post '/api/v1/auth/register', params: params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include(match(/academic email/i))
        end

        it 'returns error for weak password' do
          params = valid_params.deep_merge(user: { password: 'weak' })
          post '/api/v1/auth/register', params: params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_present
        end
      end
    end

    describe 'teacher registration' do
      let(:valid_params) do
        {
          registration_type: 'teacher',
          user: {
            email: "teacher#{SecureRandom.hex(4)}@ac-nantes.fr",
            password: 'Password123!',
            password_confirmation: 'Password123!',
            first_name: 'Jane',
            last_name: 'Smith',
            birthday: '1985-03-20',
            role: 'school_teacher',
            accept_privacy_policy: true
          }
        }
      end

      context 'with valid data' do
        it 'creates user successfully' do
          post '/api/v1/auth/register', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['message']).to include('successful')
          
          user = User.find_by(email: valid_params[:user][:email])
          expect(user).to be_present
          expect(user.independent_teacher).to be_present
        end

        it 'returns error for non-academic email' do
          params = valid_params.deep_merge(user: { email: 'teacher@example.com' })
          post '/api/v1/auth/register', params: params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include(match(/academic email/i))
        end
      end
    end

    describe 'school registration' do
      let(:valid_params) do
        {
          registration_type: 'school',
          user: {
            email: "director#{SecureRandom.hex(4)}@ac-nantes.fr",
            password: 'Password123!',
            password_confirmation: 'Password123!',
            first_name: 'Marie',
            last_name: 'Dupont',
            birthday: '1975-06-15',
            role: 'school_director',
            accept_privacy_policy: true
          },
          school: {
            name: 'Test School',
            zip_code: '44000',
            city: 'Nantes',
            school_type: 'lycee'
          }
        }
      end

      context 'with valid data' do
        it 'creates user and school successfully' do
          post '/api/v1/auth/register', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['message']).to include('successful')
          
          user = User.find_by(email: valid_params[:user][:email])
          expect(user).to be_present
          expect(user.user_schools.count).to eq(1)
          expect(user.user_schools.first.role).to eq('superadmin')
          expect(user.user_schools.first.status).to eq('pending')
        end
      end
    end

    describe 'company registration' do
      let!(:company_type) { create(:company_type) }
      let(:valid_params) do
        {
          registration_type: 'company',
          user: {
            email: "ceo#{SecureRandom.hex(4)}@example.com",
            password: 'Password123!',
            password_confirmation: 'Password123!',
            first_name: 'Sophie',
            last_name: 'Bernard',
            birthday: '1980-01-01',
            role: 'company_director',
            accept_privacy_policy: true
          },
          company: {
            name: 'Test Company',
            description: 'A test company',
            zip_code: '75001',
            city: 'Paris',
            company_type_id: company_type.id,
            referent_phone_number: '0123456789'
          }
        }
      end

      context 'with valid data' do
        it 'creates user and company successfully' do
          post '/api/v1/auth/register', params: valid_params.to_json, headers: { 'Content-Type' => 'application/json' }
          
          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json['message']).to include('successful')
          
          user = User.find_by(email: valid_params[:user][:email])
          expect(user).to be_present
          expect(user.user_company.count).to eq(1)
          expect(user.user_company.first.role).to eq('superadmin')
          expect(user.user_company.first.status).to eq('pending')
        end
      end
    end

    describe 'validation errors' do
      it 'returns error for invalid registration_type' do
        params = { registration_type: 'invalid_type', user: {} }
        post '/api/v1/auth/register', params: params.to_json, headers: { 'Content-Type' => 'application/json' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(match(/Invalid registration_type/i))
      end

      it 'returns error for wrong role for registration type' do
        params = {
          registration_type: 'teacher',
          user: {
            email: "teacher#{SecureRandom.hex(4)}@ac-nantes.fr",
            password: 'Password123!',
            first_name: 'Test',
            last_name: 'User',
            birthday: '1990-01-01',
            role: 'parent',
            accept_privacy_policy: true
          }
        }
        post '/api/v1/auth/register', params: params.to_json, headers: { 'Content-Type' => 'application/json' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include(match(/Invalid role for teacher registration/i))
      end
    end
  end
end

