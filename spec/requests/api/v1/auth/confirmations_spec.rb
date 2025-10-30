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

