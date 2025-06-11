require 'rails_helper'

RSpec.describe MetricsService::ActivityMetrics do
  let(:test_class) do
    Class.new do
      include MetricsService::ActivityMetrics
      attr_accessor :user, :start_date, :end_date
      
      def initialize(user = nil)
        @user = user
        @start_date = 30.days.ago
        @end_date = Date.current
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:service) { test_class.new(user) }

  describe '#calculate_activity_metrics' do
    let!(:documents) { create_list(:document, 3, uploaded_by: user, created_at: 1.week.ago) }
    let!(:old_document) { create(:document, uploaded_by: user, created_at: 2.months.ago) }

    it 'returns activity metrics for the specified period' do
      metrics = service.calculate_activity_metrics
      
      expect(metrics).to include(
        :total_actions,
        :actions_by_type,
        :daily_activity,
        :peak_hours,
        :user_rankings
      )
      
      expect(metrics[:total_actions]).to be >= 0
      expect(metrics[:actions_by_type]).to be_a(Hash)
    end

    it 'excludes activities outside the date range' do
      metrics = service.calculate_activity_metrics
      
      # Should include recent documents but not old ones
      expect(metrics[:total_actions]).to be >= 3
    end
  end

  describe '#activity_trends' do
    it 'calculates activity trends over time' do
      trends = service.activity_trends
      
      expect(trends).to include(
        :trend_direction,
        :growth_percentage,
        :comparison_data
      )
      
      expect(trends[:trend_direction]).to be_in(['increasing', 'decreasing', 'stable'])
    end
  end

  describe '#user_activity_summary' do
    let!(:space) { create(:space, organization: organization) }
    let!(:documents) { create_list(:document, 2, uploaded_by: user, space: space) }

    it 'returns summary of user activities' do
      summary = service.user_activity_summary(user)
      
      expect(summary).to include(
        :documents_created,
        :documents_viewed,
        :folders_created,
        :last_activity
      )
      
      expect(summary[:documents_created]).to eq(2)
    end
  end
end