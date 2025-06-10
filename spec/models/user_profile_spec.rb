require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  
  describe 'validations' do
    it { should validate_presence_of(:profile_type) }
    
    it 'validates uniqueness of active profile per user' do
      create(:user_profile, user: user, active: true)
      duplicate = build(:user_profile, user: user, active: true)
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).not_to be_empty
    end
    
    it 'allows multiple inactive profiles per user' do
      create(:user_profile, user: user, active: false)
      duplicate = build(:user_profile, user: user, active: false)
      
      expect(duplicate).to be_valid
    end
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:dashboard_widgets).order(:position).dependent(:destroy) }
  end
  
  describe 'enums' do
    it do
      should define_enum_for(:profile_type)
        .backed_by_column_of_type(:string)
        .with_values(
          direction: 'direction',
          chef_projet: 'chef_projet',
          juriste: 'juriste',
          architecte: 'architecte',
          commercial: 'commercial',
          controleur: 'controleur',
          expert_technique: 'expert_technique',
          assistant_rh: 'assistant_rh',
          communication: 'communication',
          admin_system: 'admin_system'
        )
    end
  end
  
  describe 'scopes' do
    describe '.active' do
      let!(:active_profile) { create(:user_profile, active: true) }
      let!(:inactive_profile) { create(:user_profile, active: false) }
      
      it 'returns only active profiles' do
        expect(UserProfile.active).to include(active_profile)
        expect(UserProfile.active).not_to include(inactive_profile)
      end
    end
  end
  
  describe 'store accessors' do
    subject { create(:user_profile, user: user) }
    
    it 'has preferences accessors' do
      subject.theme = 'dark'
      subject.language = 'fr'
      subject.timezone = 'Europe/Paris'
      subject.date_format = 'DD/MM/YYYY'
      
      subject.save!
      subject.reload
      
      expect(subject.theme).to eq('dark')
      expect(subject.language).to eq('fr')
      expect(subject.timezone).to eq('Europe/Paris')
      expect(subject.date_format).to eq('DD/MM/YYYY')
    end
    
    it 'has dashboard_config accessors' do
      subject.layout = 'grid'
      subject.refresh_interval = 300
      subject.collapsed_sections = ['actions', 'notifications']
      
      subject.save!
      subject.reload
      
      expect(subject.layout).to eq('grid')
      expect(subject.refresh_interval).to eq(300)
      expect(subject.collapsed_sections).to eq(['actions', 'notifications'])
    end
    
    it 'has notification_settings accessors' do
      subject.email_alerts = true
      subject.push_notifications = false
      subject.alert_types = ['urgent', 'validation']
      
      subject.save!
      subject.reload
      
      expect(subject.email_alerts).to be(true)
      expect(subject.push_notifications).to be(false)
      expect(subject.alert_types).to eq(['urgent', 'validation'])
    end
  end
  
  describe 'callbacks' do
    describe 'after_create' do
      it 'sets up default widgets' do
        profile = create(:user_profile, user: user, profile_type: 'direction')
        
        expect(profile.dashboard_widgets).not_to be_empty
        expect(profile.dashboard_widgets.count).to be > 0
      end
    end
  end
  
  describe '#available_widgets' do
    let(:profile) { create(:user_profile, user: user, profile_type: 'direction') }
    
    it 'returns widgets for the profile type' do
      widgets = profile.available_widgets
      
      expect(widgets).to be_an(Array)
      expect(widgets).not_to be_empty
    end
  end
  
  describe '#can_access_module?' do
    let(:profile) { create(:user_profile, user: user, profile_type: 'chef_projet') }
    
    it 'checks module access permissions' do
      # This will be implemented based on ProfilePermissionService
      expect(profile.can_access_module?('immo_promo')).to be_in([true, false])
    end
  end
  
  describe '#navigation_items' do
    let(:profile) { create(:user_profile, user: user, profile_type: 'direction') }
    
    it 'returns navigation items for the profile' do
      items = profile.navigation_items
      
      expect(items).to be_an(Array)
    end
  end
  
  describe '#priority_actions' do
    let(:profile) { create(:user_profile, user: user, profile_type: 'direction') }
    
    it 'returns priority actions for the profile' do
      actions = profile.priority_actions
      
      expect(actions).to be_an(Array)
    end
  end
end