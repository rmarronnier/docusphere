require 'rails_helper'

RSpec.describe MetricsService::WidgetData do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:service) { MetricsService.new(user) }
  
  subject { service }
  
  describe '#widget_metrics' do
    before do
      # Create test data
      create_list(:document, 5, organization: organization, created_at: 2.days.ago)
      create_list(:document, 3, organization: organization, created_at: 1.week.ago)
      
      # Create tasks for the user
      create_list(:validation_request, 2, 
        user: user, 
        status: 'pending',
        created_at: 1.day.ago
      )
    end
    
    it 'returns metrics formatted for dashboard widgets' do
      result = subject.widget_metrics
      
      expect(result).to be_a(Hash)
      expect(result.keys).to include(
        :summary_stats,
        :activity_chart,
        :performance_indicators,
        :recent_items
      )
    end
    
    describe 'summary_stats' do
      it 'includes key statistics' do
        stats = subject.widget_metrics[:summary_stats]
        
        expect(stats).to include(
          :total_documents,
          :pending_tasks,
          :weekly_activity,
          :completion_rate
        )
      end
      
      it 'calculates correct document count' do
        stats = subject.widget_metrics[:summary_stats]
        
        expect(stats[:total_documents]).to eq(8)
      end
      
      it 'calculates pending tasks for user' do
        stats = subject.widget_metrics[:summary_stats]
        
        expect(stats[:pending_tasks]).to eq(2)
      end
    end
    
    describe 'activity_chart' do
      it 'returns chart-ready data' do
        chart_data = subject.widget_metrics[:activity_chart]
        
        expect(chart_data).to include(
          :labels,
          :datasets
        )
        
        expect(chart_data[:labels]).to be_an(Array)
        expect(chart_data[:labels].size).to eq(7) # Last 7 days
      end
      
      it 'includes multiple datasets' do
        datasets = subject.widget_metrics[:activity_chart][:datasets]
        
        expect(datasets).to be_an(Array)
        expect(datasets.first).to include(
          :label,
          :data,
          :backgroundColor,
          :borderColor
        )
      end
    end
    
    describe 'performance_indicators' do
      it 'returns key performance indicators' do
        kpis = subject.widget_metrics[:performance_indicators]
        
        expect(kpis).to be_an(Array)
        expect(kpis.first).to include(
          :label,
          :value,
          :change,
          :trend
        )
      end
      
      it 'calculates trends correctly' do
        # Create more recent activity
        create_list(:document, 10, organization: organization, created_at: 1.hour.ago)
        
        kpis = subject.widget_metrics[:performance_indicators]
        growth_kpi = kpis.find { |k| k[:label] == 'Growth' }
        
        expect(growth_kpi[:trend]).to eq('up')
        expect(growth_kpi[:change]).to be > 0
      end
    end
    
    describe 'recent_items' do
      it 'returns recent activity items' do
        recent = subject.widget_metrics[:recent_items]
        
        expect(recent).to be_an(Array)
        expect(recent.size).to be <= 10
      end
      
      it 'includes item details' do
        recent = subject.widget_metrics[:recent_items]
        
        expect(recent.first).to include(
          :type,
          :title,
          :timestamp,
          :icon,
          :url
        )
      end
    end
  end
  
  describe '#format_for_stat_card' do
    it 'formats data for stat card component' do
      data = subject.send(:format_for_stat_card, 
        'Total Documents', 
        150, 
        previous: 120
      )
      
      expect(data).to eq({
        title: 'Total Documents',
        value: 150,
        change: 25.0,
        trend: 'increase',
        formatted_value: '150',
        formatted_change: '+25.0%'
      })
    end
    
    it 'handles decrease trends' do
      data = subject.send(:format_for_stat_card, 
        'Pending Tasks', 
        8, 
        previous: 12
      )
      
      expect(data[:trend]).to eq('decrease')
      expect(data[:formatted_change]).to eq('-33.33%')
    end
  end
  
  describe '#format_for_chart' do
    it 'formats time series data for charts' do
      data_points = {
        Date.today - 2 => 5,
        Date.today - 1 => 8,
        Date.today => 12
      }
      
      result = subject.send(:format_for_chart, data_points, 'Documents')
      
      expect(result).to include(
        :labels,
        :datasets
      )
      
      expect(result[:labels]).to eq(data_points.keys.map(&:to_s))
      expect(result[:datasets].first[:data]).to eq([5, 8, 12])
    end
  end
  
  describe '#widget_specific_metrics' do
    context 'for notifications widget' do
      let!(:notifications) do
        create_list(:notification, 3, user: user, read_at: nil)
        create_list(:notification, 2, user: user, read_at: 1.day.ago)
      end
      
      it 'returns unread notification count' do
        metrics = subject.send(:widget_specific_metrics, 'notifications')
        
        expect(metrics[:unread_count]).to eq(3)
        expect(metrics[:total_count]).to eq(5)
      end
    end
    
    context 'for tasks widget' do
      it 'returns task breakdown by status' do
        create(:validation_request, user: user, status: 'pending')
        create(:validation_request, user: user, status: 'in_progress')
        create(:validation_request, user: user, status: 'completed')
        
        metrics = subject.send(:widget_specific_metrics, 'tasks')
        
        expect(metrics).to include(
          pending: 1,
          in_progress: 1,
          completed: 1,
          overdue: 0
        )
      end
    end
  end
end