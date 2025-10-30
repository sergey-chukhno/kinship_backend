require 'rails_helper'

RSpec.describe 'API V1 Skills', type: :request do
  let!(:skill1) { create(:skill, name: 'Math', official: true) }
  let!(:skill2) { create(:skill, name: 'Science', official: true) }
  let!(:sub_skill1) { create(:sub_skill, skill: skill1, name: 'Algebra') }
  let!(:sub_skill2) { create(:sub_skill, skill: skill1, name: 'Geometry') }

  describe 'GET /api/v1/skills' do
    context 'public endpoint' do
      it 'returns all skills without authentication' do
        get '/api/v1/skills'
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to be >= 2
        expect(json['data'].map { |s| s['name'] }).to include('Math', 'Science')
      end

      it 'includes sub_skills in response' do
        get '/api/v1/skills'
        
        json = JSON.parse(response.body)
        math_skill = json['data'].find { |s| s['name'] == 'Math' }
        expect(math_skill['sub_skills']).to be_an(Array)
        expect(math_skill['sub_skills'].length).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/skills/:id/sub_skills' do
    context 'public endpoint' do
      it 'returns sub_skills for a skill without authentication' do
        get "/api/v1/skills/#{skill1.id}/sub_skills"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['skill']).to be_present
        expect(json['skill']['id']).to eq(skill1.id)
        expect(json['sub_skills']).to be_an(Array)
        expect(json['sub_skills'].length).to eq(2)
        expect(json['sub_skills'].map { |s| s['name'] }).to contain_exactly('Algebra', 'Geometry')
      end

      it 'returns 404 for non-existent skill' do
        get '/api/v1/skills/99999/sub_skills'
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

