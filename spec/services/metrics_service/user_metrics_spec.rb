require 'rails_helper'

RSpec.describe MetricsService::UserMetrics do
  let(:test_class) do
    Class.new do
      include MetricsService::UserMetrics
      attr_accessor :user
      
      def initialize(user = nil)
        @user = user
      end
    end
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:service) { test_class.new(user) }

  describe '#calculate_user_metrics' do
    let!(:profile) { create(:user_profile, user: user, profile_type: 'assistant_rh') }
    let!(:documents) { create_list(:document, 5, uploaded_by: user) }

    it 'returns metrics based on user profile' do
      metrics = service.calculate_user_metrics
      
      expect(metrics).to include(
        :profile_type,
        :usage_stats,
        :performance_indicators,
        :personalized_insights
      )
      
      expect(metrics[:profile_type]).to eq('assistant_rh')
    end
  end

  describe '#user_performance_score' do
    it 'calculates a performance score for the user' do
      score = service.user_performance_score
      
      expect(score).to be_a(Hash)
      expect(score).to include(
        :overall_score,
        :activity_score,
        :collaboration_score,
        :compliance_score
      )
      
      expect(score[:overall_score]).to be_between(0, 100)
    end
  end

  describe '#user_recommendations' do
    it 'provides personalized recommendations' do
      recommendations = service.user_recommendations
      
      expect(recommendations).to be_an(Array)
      recommendations.each do |rec|
        expect(rec).to include(:type, :message, :priority)
      end
    end
  end
end