require 'rails_helper'

RSpec.describe 'API V1 Email Confirmation', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'Password123!', confirmed_at: nil) }

  describe 'GET /api/v1/auth/confirmation' do
    context 'with valid confirmation token' do
      it 'confirms user email successfully' do
        user.send_confirmation_instructions
        token = user.confirmation_token
        
        get "/api/v1/auth/confirmation?confirmation_token=#{token}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['confirmed']).to be true
        expect(json['message']).to include('successfully')
        expect(json['email']).to eq(user.email)
        
        user.reload
        expect(user.confirmed?).to be true
      end
    end
    
    context 'with school registration' do
      it 'auto-confirms UserSchool and School when superadmin confirms email' do
        school = create(:school, status: :pending)
        user = create(:user, role: 'school_director', email: 'director@ac-nantes.fr', confirmed_at: nil)
        user_school = create(:user_school, user: user, school: school, role: :superadmin)
        # Override callback that auto-confirms non-teacher UserSchools
        user_school.update_column(:status, :pending) if user_school.confirmed?
        
        user.send_confirmation_instructions
        token = user.confirmation_token
        
        get "/api/v1/auth/confirmation?confirmation_token=#{token}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['confirmed']).to be true
        
        user.reload
        user_school.reload
        school_id = school.id
        school = School.find(school_id)
        
        expect(user.confirmed?).to be true
        expect(user_school.status).to eq('confirmed')
        expect(school.status.to_s).to eq('confirmed')
      end
    end
    
    context 'with company registration' do
      it 'auto-confirms UserCompany when superadmin confirms email' do
        company = create(:company, status: :confirmed)
        user = create(:user, role: 'company_director', confirmed_at: nil)
        user_company = create(:user_company, user: user, company: company, role: :superadmin, status: :pending)
        
        user.send_confirmation_instructions
        token = user.confirmation_token
        
        get "/api/v1/auth/confirmation?confirmation_token=#{token}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['confirmed']).to be true
        
        user.reload
        user_company.reload
        company.reload
        
        expect(user.confirmed?).to be true
        expect(user_company.status).to eq('confirmed')
        expect(company.status).to eq('confirmed') # Company already confirmed during registration
      end
    end

    context 'with invalid confirmation token' do
      it 'returns error for invalid token' do
        get '/api/v1/auth/confirmation?confirmation_token=invalid_token'
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['confirmed']).to be false
        expect(json['error']).to be_present
      end
    end

    context 'without authentication' do
      it 'does not require authentication' do
        user.send_confirmation_instructions
        token = user.confirmation_token
        
        get "/api/v1/auth/confirmation?confirmation_token=#{token}"
        
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

