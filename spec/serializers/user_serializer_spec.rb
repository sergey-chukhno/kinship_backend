require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  describe '#has_personal_dashboard?' do
    context 'with personal user role' do
      it 'returns true for parent role' do
        user = build(:user, role: 'parent')
        serializer = UserSerializer.new(user)
        expect(serializer.send(:has_personal_dashboard?)).to be true
      end
      
      it 'returns true for tutor role' do
        user = build(:user, role: 'tutor')
        serializer = UserSerializer.new(user)
        expect(serializer.send(:has_personal_dashboard?)).to be true
      end
      
      it 'returns true for voluntary role' do
        user = build(:user, role: 'voluntary')
        serializer = UserSerializer.new(user)
        expect(serializer.send(:has_personal_dashboard?)).to be true
      end
    end
    
    context 'with teacher role' do
      it 'returns false for school_teacher role' do
        user = build(:user, role: 'school_teacher')
        serializer = UserSerializer.new(user)
        expect(serializer.send(:has_personal_dashboard?)).to be false
      end
    end
    
    context 'with school admin role' do
      it 'returns false for school_director role' do
        user = build(:user, role: 'school_director')
        serializer = UserSerializer.new(user)
        expect(serializer.send(:has_personal_dashboard?)).to be false
      end
    end
    
    context 'with company admin role' do
      it 'returns false for company_director role' do
        user = build(:user, role: 'company_director')
        serializer = UserSerializer.new(user)
        expect(serializer.send(:has_personal_dashboard?)).to be false
      end
    end
  end
  
  describe '#available_contexts' do
    context 'with personal user' do
      let(:user) { create(:user, role: 'parent') }
      let(:serializer) { UserSerializer.new(user, include_contexts: true) }
      
      it 'includes user_dashboard' do
        contexts = serializer.send(:available_contexts)
        expect(contexts[:user_dashboard]).to be true
        expect(contexts[:teacher_dashboard]).to be false
      end
    end
    
    context 'with teacher' do
      let(:user) { create(:user, :school_teacher) }
      let(:serializer) { UserSerializer.new(user, include_contexts: true) }
      
      it 'includes teacher_dashboard' do
        contexts = serializer.send(:available_contexts)
        expect(contexts[:user_dashboard]).to be false
        expect(contexts[:teacher_dashboard]).to be true
      end
    end
    
    context 'with school director' do
      let(:school) { create(:school) }
      let(:user) { create(:user, role: 'school_director', email: 'director@ac-nantes.fr') }
      let(:user_school) { create(:user_school, user: user, school: school, role: :superadmin, status: :confirmed) }
      let(:serializer) { UserSerializer.new(user, include_contexts: true) }
      
      before { user_school }
      
      it 'includes schools array' do
        contexts = serializer.send(:available_contexts)
        expect(contexts[:user_dashboard]).to be false
        expect(contexts[:teacher_dashboard]).to be false
        expect(contexts[:schools]).to be_an(Array)
        expect(contexts[:schools].length).to eq(1)
        expect(contexts[:schools].first[:id]).to eq(school.id)
      end
    end
  end
end

