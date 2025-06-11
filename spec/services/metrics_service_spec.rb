require 'rails_helper'

RSpec.describe MetricsService, type: :service do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:profile) { create(:user_profile, user: user, profile_type: profile_type) }
  let(:service) { described_class.new(user) }
  
  before do
    user.active_profile = profile
    user.save
    
    # Create some test data
    space = create(:space, organization: organization)
    create_list(:document, 5, uploaded_by: user, space: space, created_at: 1.day.ago)
    create_list(:document, 3, uploaded_by: user, space: space, created_at: 1.week.ago)
    create_list(:notification, 4, user: user, read_at: nil)
    create_list(:notification, 2, user: user, read_at: 1.hour.ago)
  end

  describe '#key_metrics' do
    context 'for direction profile' do
      let(:profile_type) { 'direction' }
      
      it 'returns direction-specific metrics' do
        metrics = service.key_metrics
        
        expect(metrics).to be_a(Hash)
        expect(metrics[:total_projects]).to be_present
        expect(metrics[:active_projects]).to be_present
        expect(metrics[:budget_consumed]).to be_present
        expect(metrics[:pending_validations]).to be_present
      end
      
      it 'includes calculated percentages' do
        metrics = service.key_metrics
        
        expect(metrics[:project_completion_rate]).to be_a(Numeric)
        expect(metrics[:budget_utilization_rate]).to be_a(Numeric)
      end
    end
    
    context 'for chef_projet profile' do
      let(:profile_type) { 'chef_projet' }
      
      it 'returns project manager metrics' do
        metrics = service.key_metrics
        
        expect(metrics[:tasks_completed]).to be_present
        expect(metrics[:tasks_pending]).to be_present
        expect(metrics[:team_size]).to be_present
        expect(metrics[:project_progress]).to be_present
      end
    end
    
    context 'for default profile' do
      let(:profile_type) { 'assistant_rh' }
      
      it 'returns basic metrics' do
        metrics = service.key_metrics
        
        expect(metrics[:documents_uploaded]).to be_present
        expect(metrics[:unread_notifications]).to eq(4)
        expect(metrics[:recent_activity]).to be_present
      end
    end
  end
  
  describe '#activity_summary' do
    let(:profile_type) { 'direction' }
    
    it 'returns activity data for the last 30 days' do
      summary = service.activity_summary
      
      expect(summary).to be_a(Hash)
      expect(summary[:period]).to eq("30 derniers jours")
      expect(summary).to include(:documents, :tasks, :notifications, :activity_score)
    end
    
    it 'includes document activity counts' do
      summary = service.activity_summary
      
      expect(summary[:documents]).to include(:created, :modified, :shared)
      expect(summary[:documents][:created]).to be >= 5 # We created 5 documents 1 day ago
    end
  end
  
  describe '#activity_by_day' do
    let(:profile_type) { 'direction' }
    
    it 'returns daily activity data as an array' do
      daily_data = service.activity_by_day
      
      expect(daily_data).to be_an(Array)
      expect(daily_data.size).to eq(31) # 30 days + today
      expect(daily_data.first).to include(:date, :count, :type)
    end
    
    it 'groups activities by day' do
      daily_data = service.activity_by_day
      today_activity = daily_data.find { |s| s[:date] == Date.today }
      
      expect(today_activity).to be_present
    end
  end
  
  describe '#performance_indicators' do
    let(:profile_type) { 'chef_projet' }
    
    it 'returns performance KPIs' do
      indicators = service.performance_indicators
      
      expect(indicators).to be_a(Hash)
      expect(indicators[:efficiency_score]).to be_between(0, 100)
      expect(indicators[:quality_score]).to be_between(0, 100)
      expect(indicators[:timeliness_score]).to be_between(0, 100)
    end
  end
  
  describe '#trending_metrics' do
    let(:profile_type) { 'direction' }
    
    it 'returns metrics with trend information' do
      trends = service.trending_metrics
      
      expect(trends).to be_an(Array)
      expect(trends.first).to include(
        :name,
        :value,
        :trend,        # up, down, stable
        :change,       # percentage change
        :period        # comparison period
      )
    end
    
    it 'calculates trend direction correctly' do
      # Create more recent documents
      space = create(:space, organization: organization)
      create_list(:document, 10, uploaded_by: user, space: space, created_at: 1.hour.ago)
      
      trends = service.trending_metrics
      documents_trend = trends.find { |t| t[:name] == 'Documents' }
      
      expect(documents_trend[:trend]).to eq('up')
      expect(documents_trend[:change]).to be > 0
    end
  end
  
  describe '#widget_metrics' do
    let(:profile_type) { 'commercial' }
    
    it 'returns metrics formatted for dashboard widgets' do
      widget_data = service.widget_metrics('statistics')
      
      expect(widget_data).to be_a(Hash)
      expect(widget_data[:title]).to be_present
      expect(widget_data[:metrics]).to be_an(Array)
      expect(widget_data[:chart_data]).to be_present
    end
    
    it 'returns different data based on widget type' do
      stats_data = service.widget_metrics('statistics')
      activity_data = service.widget_metrics('activity')
      
      expect(stats_data[:metrics]).not_to eq(activity_data[:metrics])
    end
  end
  
  describe '#comparison_data' do
    let(:profile_type) { 'controleur' }
    
    it 'returns comparison data between periods' do
      comparison = service.comparison_data(:week)
      
      expect(comparison).to include(
        :current_period,
        :previous_period,
        :metrics
      )
      
      expect(comparison[:metrics]).to be_an(Array)
      expect(comparison[:metrics].first).to include(
        :name,
        :current,
        :previous,
        :change_percentage
      )
    end
  end
end