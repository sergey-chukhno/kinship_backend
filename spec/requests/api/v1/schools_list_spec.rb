require 'rails_helper'

RSpec.describe 'API V1 Schools - List for Joining', type: :request do
  let!(:confirmed_school1) { create(:school, :confirmed, name: 'School A', city: 'Paris') }
  let!(:confirmed_school2) { create(:school, :confirmed, name: 'School B', city: 'Lyon') }
  let!(:pending_school) { create(:school, :pending, name: 'School C') }

  describe 'GET /api/v1/schools/list_for_joining' do
    context 'public endpoint' do
      it 'returns only confirmed schools without authentication' do
        get '/api/v1/schools/list_for_joining'
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to eq(2)
        expect(json['data'].map { |s| s['name'] }).to contain_exactly('School A', 'School B')
        expect(json['data'].map { |s| s['name'] }).not_to include('School C')
      end

      it 'includes school details' do
        get '/api/v1/schools/list_for_joining'
        
        json = JSON.parse(response.body)
        school = json['data'].first
        expect(school).to have_key('id')
        expect(school).to have_key('name')
        expect(school).to have_key('city')
        expect(school).to have_key('zip_code')
        expect(school).to have_key('school_type')
      end
    end
  end
end

