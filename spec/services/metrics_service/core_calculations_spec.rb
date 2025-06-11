require 'rails_helper'

RSpec.describe MetricsService::CoreCalculations do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:service) { MetricsService.new(user) }
  
  subject { service }
  
  describe '#calculate_percentage' do
    it 'calculates percentage correctly' do
      expect(subject.send(:calculate_percentage, 25, 100)).to eq(25.0)
      expect(subject.send(:calculate_percentage, 33, 66)).to eq(50.0)
    end
    
    it 'handles zero total' do
      expect(subject.send(:calculate_percentage, 10, 0)).to eq(0.0)
    end
    
    it 'handles nil values' do
      expect(subject.send(:calculate_percentage, nil, 100)).to eq(0.0)
      expect(subject.send(:calculate_percentage, 10, nil)).to eq(0.0)
    end
    
    it 'rounds to specified decimal places' do
      expect(subject.send(:calculate_percentage, 1, 3, 2)).to eq(33.33)
      expect(subject.send(:calculate_percentage, 1, 3, 0)).to eq(33.0)
    end
  end
  
  describe '#calculate_growth_rate' do
    it 'calculates positive growth' do
      expect(subject.send(:calculate_growth_rate, 100, 150)).to eq(50.0)
    end
    
    it 'calculates negative growth' do
      expect(subject.send(:calculate_growth_rate, 150, 100)).to eq(-33.33)
    end
    
    it 'handles zero previous value' do
      expect(subject.send(:calculate_growth_rate, 0, 100)).to eq(100.0)
    end
    
    it 'handles both values being zero' do
      expect(subject.send(:calculate_growth_rate, 0, 0)).to eq(0.0)
    end
  end
  
  describe '#calculate_trend' do
    it 'identifies increasing trend' do
      data_points = [10, 15, 20, 25, 30]
      expect(subject.send(:calculate_trend, data_points)).to eq('increasing')
    end
    
    it 'identifies decreasing trend' do
      data_points = [30, 25, 20, 15, 10]
      expect(subject.send(:calculate_trend, data_points)).to eq('decreasing')
    end
    
    it 'identifies stable trend' do
      data_points = [20, 21, 20, 19, 20]
      expect(subject.send(:calculate_trend, data_points)).to eq('stable')
    end
    
    it 'handles empty data' do
      expect(subject.send(:calculate_trend, [])).to eq('stable')
    end
  end
  
  describe '#calculate_activity_score' do
    let(:start_date) { 7.days.ago }
    let(:end_date) { Time.current }
    
    before do
      # Create various activities
      create_list(:document, 5, organization: organization, created_at: 3.days.ago)
      create_list(:document, 3, organization: organization, updated_at: 1.day.ago)
      
      # Create user activities
      5.times do
        doc = create(:document, organization: organization)
        doc.versions.create!(
          event: 'update',
          whodunnit: user.id.to_s,
          created_at: 2.days.ago
        )
      end
    end
    
    it 'calculates activity score based on actions' do
      score = subject.calculate_activity_score(start_date, end_date)
      
      expect(score).to be > 0
      expect(score).to be <= 100
    end
    
    it 'weights different activities appropriately' do
      # Create high-value activities
      create(:document_validation, 
        document: create(:document, organization: organization),
        validated_by: user,
        validated_at: 1.day.ago
      )
      
      score_with_validation = subject.calculate_activity_score(start_date, end_date)
      base_score = subject.calculate_activity_score(start_date, end_date)
      
      expect(score_with_validation).to be > base_score
    end
  end
  
  describe '#calculate_performance_index' do
    it 'calculates weighted performance index' do
      metrics = {
        efficiency: 85,
        quality: 90,
        timeliness: 75,
        engagement: 80
      }
      
      index = subject.send(:calculate_performance_index, metrics)
      
      expect(index).to be_between(75, 90)
    end
    
    it 'handles missing metrics' do
      metrics = {
        efficiency: 85,
        quality: 90
      }
      
      index = subject.send(:calculate_performance_index, metrics)
      
      expect(index).to be > 0
    end
  end
  
  describe '#format_currency' do
    it 'formats cents to currency string' do
      expect(subject.send(:format_currency, 150000)).to eq('€1,500.00')
      expect(subject.send(:format_currency, 99)).to eq('€0.99')
    end
    
    it 'handles nil and zero values' do
      expect(subject.send(:format_currency, nil)).to eq('€0.00')
      expect(subject.send(:format_currency, 0)).to eq('€0.00')
    end
  end
  
  describe '#calculate_time_range_metrics' do
    it 'calculates metrics for different time ranges' do
      # Create data across different time periods
      create(:document, organization: organization, created_at: 1.hour.ago)
      create(:document, organization: organization, created_at: 1.day.ago)
      create(:document, organization: organization, created_at: 1.week.ago)
      create(:document, organization: organization, created_at: 1.month.ago)
      
      daily_metrics = subject.send(:calculate_time_range_metrics, :daily)
      weekly_metrics = subject.send(:calculate_time_range_metrics, :weekly)
      monthly_metrics = subject.send(:calculate_time_range_metrics, :monthly)
      
      expect(daily_metrics[:count]).to eq(1)
      expect(weekly_metrics[:count]).to be >= 2
      expect(monthly_metrics[:count]).to be >= 3
    end
  end
  
  describe '#aggregate_metrics' do
    it 'aggregates multiple metric sources' do
      sources = [
        { documents: 10, tasks: 5 },
        { documents: 15, tasks: 8 },
        { documents: 20, users: 3 }
      ]
      
      result = subject.send(:aggregate_metrics, sources)
      
      expect(result).to eq({
        documents: 45,
        tasks: 13,
        users: 3
      })
    end
  end
  
  describe '#calculate_efficiency_score' do
    it 'calculates efficiency based on completion time' do
      # Tasks completed on time
      on_time = 8
      # Tasks completed late  
      late = 2
      
      score = subject.send(:calculate_efficiency_score, on_time, late)
      
      expect(score).to eq(80.0)
    end
  end
end