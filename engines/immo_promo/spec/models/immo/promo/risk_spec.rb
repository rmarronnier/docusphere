require 'rails_helper'

RSpec.describe Immo::Promo::Risk, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:risk) { create(:immo_promo_risk, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_inclusion_of(:probability).in_range(1..5) }
    it { is_expected.to validate_inclusion_of(:impact).in_range(1..5) }
  end

  describe 'enums' do
    it 'defines category and status' do
      expect(risk).to respond_to(:category)
      expect(risk).to respond_to(:status)
    end
  end

  describe '#risk_score' do
    it 'calculates risk score as probability * impact' do
      risk.update!(probability: 3, impact: 4)
      expect(risk.risk_score).to eq(12)
    end
  end

  describe '#severity_level' do
    it 'determines severity based on risk score' do
      risk.update!(probability: 5, impact: 5)
      expect(risk.severity_level).to eq(:critical)
      
      risk.update!(probability: 2, impact: 2)
      expect(risk.severity_level).to eq(:low)
    end
  end
end