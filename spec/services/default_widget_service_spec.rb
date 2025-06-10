require 'rails_helper'

RSpec.describe DefaultWidgetService do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:profile) { create(:user_profile, user: user, profile_type: profile_type) }
  let(:service) { described_class.new(profile) }
  
  describe '#generate_widgets' do
    context 'for direction profile' do
      let(:profile_type) { 'direction' }
      
      it 'returns direction-specific widgets' do
        widgets = service.generate_widgets
        
        expect(widgets).to be_an(Array)
        expect(widgets).not_to be_empty
        
        widget_types = widgets.map { |w| w[:type] }
        expect(widget_types).to include('portfolio_overview')
        expect(widget_types).to include('financial_summary')
        expect(widget_types).to include('risk_matrix')
        expect(widget_types).to include('kpi_dashboard')
      end
      
      it 'includes correct widget sizes' do
        widgets = service.generate_widgets
        
        portfolio_widget = widgets.find { |w| w[:type] == 'portfolio_overview' }
        expect(portfolio_widget[:width]).to eq(2)
        expect(portfolio_widget[:height]).to eq(1)
      end
      
      it 'includes widget configuration' do
        widgets = service.generate_widgets
        
        widgets.each do |widget|
          expect(widget).to have_key(:config)
          expect(widget[:config]).to be_a(Hash)
          expect(widget[:visible]).to be(true)
        end
      end
    end
    
    context 'for chef_projet profile' do
      let(:profile_type) { 'chef_projet' }
      
      it 'returns chef_projet-specific widgets' do
        widgets = service.generate_widgets
        
        widget_types = widgets.map { |w| w[:type] }
        expect(widget_types).to include('project_timeline')
        expect(widget_types).to include('task_kanban')
        expect(widget_types).to include('team_availability')
        expect(widget_types).to include('milestone_tracker')
      end
      
      it 'has correct task_kanban configuration' do
        widgets = service.generate_widgets
        task_kanban = widgets.find { |w| w[:type] == 'task_kanban' }
        
        expect(task_kanban[:width]).to eq(2)
        expect(task_kanban[:height]).to eq(2)
        expect(task_kanban[:config][:columns]).to include('todo', 'in_progress', 'review', 'done')
      end
    end
    
    context 'for juriste profile' do
      let(:profile_type) { 'juriste' }
      
      it 'returns juriste-specific widgets' do
        widgets = service.generate_widgets
        
        widget_types = widgets.map { |w| w[:type] }
        expect(widget_types).to include('permit_status')
        expect(widget_types).to include('contract_tracker')
        expect(widget_types).to include('compliance_dashboard')
        expect(widget_types).to include('regulatory_calendar')
      end
    end
    
    context 'for commercial profile' do
      let(:profile_type) { 'commercial' }
      
      it 'returns commercial-specific widgets' do
        widgets = service.generate_widgets
        
        widget_types = widgets.map { |w| w[:type] }
        expect(widget_types).to include('sales_pipeline')
        expect(widget_types).to include('inventory_status')
        expect(widget_types).to include('conversion_metrics')
        expect(widget_types).to include('top_prospects')
      end
    end
    
    context 'for unknown profile type' do
      let(:profile) { create(:user_profile, user: user, profile_type: 'assistant_rh') }
      
      it 'returns default widgets' do
        widgets = service.generate_widgets
        
        widget_types = widgets.map { |w| w[:type] }
        expect(widget_types).to include('recent_activity')
        expect(widget_types).to include('my_documents')
        expect(widget_types).to include('notifications_summary')
        expect(widget_types).to include('quick_links')
      end
    end
  end
  
  describe 'widget configurations' do
    let(:profile_type) { 'direction' }
    
    it 'provides appropriate default configs for each widget type' do
      widgets = service.generate_widgets
      
      portfolio = widgets.find { |w| w[:type] == 'portfolio_overview' }
      expect(portfolio[:config]).to include(
        show_inactive: false,
        group_by: 'status',
        refresh_interval: 300
      )
      
      financial = widgets.find { |w| w[:type] == 'financial_summary' }
      expect(financial[:config]).to include(
        currency: 'EUR',
        show_variance: true,
        comparison_period: 'month'
      )
    end
  end
  
  describe 'widget ordering' do
    let(:profile_type) { 'chef_projet' }
    
    it 'maintains widget order through array index' do
      widgets = service.generate_widgets
      
      # The position should be determined by array index when creating widgets
      expect(widgets.first[:type]).to eq('project_timeline')
      expect(widgets.second[:type]).to eq('task_kanban')
    end
  end
end