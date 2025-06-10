require 'rails_helper'

RSpec.describe DashboardWidget, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:user_profile) { create(:user_profile, user: user) }
  
  describe 'validations' do
    it { should validate_presence_of(:widget_type) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:width).is_greater_than(0) }
    it { should validate_numericality_of(:height).is_greater_than(0) }
  end
  
  describe 'associations' do
    it { should belong_to(:user_profile) }
  end
  
  describe 'default values' do
    let(:widget) { DashboardWidget.new }
    
    it 'sets default width to 1' do
      expect(widget.width).to eq(1)
    end
    
    it 'sets default height to 1' do
      expect(widget.height).to eq(1)
    end
    
    it 'sets default visible to true' do
      expect(widget.visible).to be(true)
    end
    
    it 'sets default config to empty hash' do
      expect(widget.config).to eq({})
    end
  end
  
  describe 'scopes' do
    let!(:visible_widget) { create(:dashboard_widget, user_profile: user_profile, visible: true) }
    let!(:hidden_widget) { create(:dashboard_widget, user_profile: user_profile, visible: false) }
    
    describe '.visible' do
      it 'returns only visible widgets' do
        expect(DashboardWidget.visible).to include(visible_widget)
        expect(DashboardWidget.visible).not_to include(hidden_widget)
      end
    end
  end
  
  describe 'ordering' do
    let(:user_profile) { create(:user_profile, user: user) }
    
    before do
      # Clear default widgets created by callback
      user_profile.dashboard_widgets.destroy_all
    end
    
    let!(:widget1) { create(:dashboard_widget, user_profile: user_profile, position: 2) }
    let!(:widget2) { create(:dashboard_widget, user_profile: user_profile, position: 1) }
    let!(:widget3) { create(:dashboard_widget, user_profile: user_profile, position: 3) }
    
    it 'is ordered by position by default through the association' do
      expect(user_profile.dashboard_widgets.reload).to eq([widget2, widget1, widget3])
    end
  end
  
  describe '#config' do
    let(:widget) { create(:dashboard_widget, user_profile: user_profile) }
    
    it 'allows storing complex configuration' do
      config = {
        'title' => 'My Widget',
        'refresh_interval' => 300,
        'filters' => ['active', 'pending'],
        'options' => {
          'show_header' => true,
          'enable_sorting' => false
        }
      }
      
      widget.config = config
      widget.save!
      widget.reload
      
      expect(widget.config).to eq(config)
    end
    
    it 'allows partial updates to config' do
      widget.config['new_key'] = 'new_value'
      widget.save!
      widget.reload
      
      expect(widget.config['new_key']).to eq('new_value')
    end
  end
  
  describe 'widget types' do
    it 'accepts various widget types' do
      types = %w[
        portfolio_overview financial_summary risk_matrix
        task_kanban project_timeline team_availability
        permit_status compliance_dashboard
        sales_pipeline inventory_status
      ]
      
      types.each do |type|
        widget = build(:dashboard_widget, user_profile: user_profile, widget_type: type)
        expect(widget).to be_valid
      end
    end
  end
end