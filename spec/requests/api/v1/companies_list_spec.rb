require 'rails_helper'

RSpec.describe 'API V1 Companies - List for Joining', type: :request do
  let!(:company_type) { create(:company_type) }
  let!(:confirmed_company1) { create(:company, :confirmed, name: 'Company A', city: 'Paris', company_type: company_type) }
  let!(:confirmed_company2) { create(:company, :confirmed, name: 'Company B', city: 'Lyon', company_type: company_type) }
  let!(:pending_company) { create(:company, :pending, name: 'Company C', company_type: company_type) }

  describe 'GET /api/v1/companies/list_for_joining' do
    context 'public endpoint' do
      it 'returns only confirmed companies without authentication' do
        get '/api/v1/companies/list_for_joining'
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to eq(2)
        expect(json['data'].map { |c| c['name'] }).to contain_exactly('Company A', 'Company B')
        expect(json['data'].map { |c| c['name'] }).not_to include('Company C')
      end

      it 'includes company details' do
        get '/api/v1/companies/list_for_joining'
        
        json = JSON.parse(response.body)
        company = json['data'].first
        expect(company).to have_key('id')
        expect(company).to have_key('name')
        expect(company).to have_key('city')
        expect(company).to have_key('zip_code')
        expect(company).to have_key('company_type')
      end
    end
  end
end

