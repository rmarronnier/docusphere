require 'rails_helper'

RSpec.describe Immo::Promo::Risk, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:risk) { build(:immo_promo_risk, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:category) }
    it 'validates probability range' do
      expect {
        build(:immo_promo_risk, project: project, probability: 6)
      }.to raise_error(ArgumentError, /'6' is not a valid probability/)
    end
    
    it 'validates impact range' do
      expect {
        build(:immo_promo_risk, project: project, impact: 0)
      }.to raise_error(ArgumentError, /'0' is not a valid impact/)
    end
  end

  describe 'enums' do
    it 'defines category and status' do
      expect(risk).to respond_to(:category)
      expect(risk).to respond_to(:status)
    end
  end

  describe '#risk_score' do
    it 'calculates risk score as probability * impact' do
      valid_risk = build(:immo_promo_risk, project: project)
      valid_risk.probability = :medium  # 3
      valid_risk.impact = :high         # 4
      expect(valid_risk.risk_score).to eq(12)
    end
  end

  describe '#severity_level' do
    it 'determines severity based on risk score' do
      critical_risk = build(:immo_promo_risk, project: project)
      critical_risk.probability = :very_high  # 5
      critical_risk.impact = :very_high       # 5
      expect(critical_risk.severity_level).to eq(:critical)
      
      low_risk = build(:immo_promo_risk, project: project)
      low_risk.probability = :low  # 2
      low_risk.impact = :low       # 2
      expect(low_risk.severity_level).to eq(:low)
    end
  end
end