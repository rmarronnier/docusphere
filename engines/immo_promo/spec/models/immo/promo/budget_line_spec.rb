require 'rails_helper'

RSpec.describe Immo::Promo::BudgetLine, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:budget) { create(:immo_promo_budget, project: project) }
  let(:budget_line) { create(:immo_promo_budget_line, budget: budget) }

  describe 'associations' do
    it { is_expected.to belong_to(:budget).class_name('Immo::Promo::Budget') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:planned_amount_cents) }
    it { is_expected.to validate_numericality_of(:planned_amount_cents).is_greater_than(0) }
  end

  describe 'monetization' do
    it 'monetizes planned_amount_cents' do
      expect(budget_line).to respond_to(:planned_amount)
      expect(budget_line.planned_amount).to be_a(Money)
    end

    it 'monetizes actual_amount_cents' do
      expect(budget_line).to respond_to(:actual_amount)
      budget_line.update!(actual_amount_cents: 50_000_00)
      expect(budget_line.actual_amount).to be_a(Money)
    end

    it 'monetizes committed_amount_cents' do
      expect(budget_line).to respond_to(:committed_amount)
      budget_line.update!(committed_amount_cents: 25_000_00)
      expect(budget_line.committed_amount).to be_a(Money)
    end

    it 'allows nil for actual_amount_cents' do
      budget_line.update!(actual_amount_cents: nil)
      expect(budget_line.actual_amount).to be_nil
    end

    it 'allows nil for committed_amount_cents' do
      budget_line.update!(committed_amount_cents: nil)
      expect(budget_line.committed_amount).to be_nil
    end
  end

  describe 'attribute aliases' do
    it 'aliases amount_cents to planned_amount_cents' do
      budget_line.amount_cents = 100_000_00
      expect(budget_line.planned_amount_cents).to eq(100_000_00)
    end

    it 'aliases spent_amount_cents to actual_amount_cents' do
      budget_line.spent_amount_cents = 75_000_00
      expect(budget_line.actual_amount_cents).to eq(75_000_00)
    end
  end

  describe 'enums' do
    it 'defines category enum' do
      expect(budget_line).to respond_to(:category)
      expect(Immo::Promo::BudgetLine.categories.keys).to include(
        'land_acquisition', 'studies', 'construction_work', 'equipment',
        'marketing', 'legal', 'administrative', 'contingency'
      )
    end

    it 'allows setting category' do
      budget_line.category = 'construction_work'
      expect(budget_line.category).to eq('construction_work')
      expect(budget_line).to be_construction_work
    end
  end

  describe 'scopes' do
    let!(:construction_line) { create(:immo_promo_budget_line, budget: budget, category: 'construction_work') }
    let!(:studies_line) { create(:immo_promo_budget_line, budget: budget, category: 'studies') }

    describe '.by_category' do
      it 'filters budget lines by category' do
        construction_lines = Immo::Promo::BudgetLine.by_category('construction_work')
        expect(construction_lines).to include(construction_line)
        expect(construction_lines).not_to include(studies_line)
      end
    end
  end

  describe '#remaining_amount' do
    it 'calculates remaining amount' do
      budget_line.update!(
        planned_amount_cents: 100_000_00,
        actual_amount_cents: 30_000_00
      )
      
      expect(budget_line.remaining_amount).to eq(Money.new(70_000_00, 'EUR'))
    end

    it 'handles nil actual_amount' do
      budget_line.update!(
        planned_amount_cents: 100_000_00,
        actual_amount_cents: nil
      )
      
      expect(budget_line.remaining_amount).to eq(Money.new(100_000_00, 'EUR'))
    end
  end

  describe '#spending_percentage' do
    it 'calculates spending percentage' do
      budget_line.update!(
        planned_amount_cents: 100_000_00,
        actual_amount_cents: 25_000_00
      )
      
      expect(budget_line.spending_percentage).to eq(25.0)
    end

    it 'validates that planned amount cannot be 0' do
      budget_line.planned_amount_cents = 0
      expect(budget_line).not_to be_valid
      expect(budget_line.errors[:planned_amount_cents]).to include("doit être supérieur à 0")
    end

    it 'handles nil actual_amount' do
      budget_line.update!(
        planned_amount_cents: 100_000_00,
        actual_amount_cents: nil
      )
      
      expect(budget_line.spending_percentage).to eq(0)
    end
  end

  describe '#is_over_budget?' do
    it 'returns true when actual exceeds planned' do
      budget_line.update!(
        planned_amount_cents: 100_000_00,
        actual_amount_cents: 120_000_00
      )
      
      expect(budget_line.is_over_budget?).to be true
    end

    it 'returns false when actual is within planned' do
      budget_line.update!(
        planned_amount_cents: 100_000_00,
        actual_amount_cents: 80_000_00
      )
      
      expect(budget_line.is_over_budget?).to be false
    end

    it 'returns false when actual_amount is nil' do
      budget_line.update!(
        planned_amount_cents: 100_000_00,
        actual_amount_cents: nil
      )
      
      expect(budget_line.is_over_budget?).to be false
    end
  end

  describe '#amount (alias method)' do
    it 'returns planned_amount' do
      budget_line.update!(planned_amount_cents: 150_000_00)
      expect(budget_line.amount).to eq(budget_line.planned_amount)
    end
  end

  describe '#spent_amount (alias method)' do
    it 'returns actual_amount' do
      budget_line.update!(actual_amount_cents: 75_000_00)
      expect(budget_line.spent_amount).to eq(budget_line.actual_amount)
    end
  end

  describe '#can_be_deleted?' do
    it 'returns true when no amounts are committed or spent' do
      budget_line.update!(
        actual_amount_cents: 0,
        committed_amount_cents: 0
      )
      
      expect(budget_line.can_be_deleted?).to be true
    end

    it 'returns true when amounts are nil' do
      budget_line.update!(
        actual_amount_cents: nil,
        committed_amount_cents: nil
      )
      
      expect(budget_line.can_be_deleted?).to be true
    end

    it 'returns false when actual amount is spent' do
      budget_line.update!(
        actual_amount_cents: 50_000_00,
        committed_amount_cents: 0
      )
      
      expect(budget_line.can_be_deleted?).to be false
    end

    it 'returns false when amount is committed' do
      budget_line.update!(
        actual_amount_cents: 0,
        committed_amount_cents: 25_000_00
      )
      
      expect(budget_line.can_be_deleted?).to be false
    end
  end

  describe 'category validation' do
    it 'accepts valid categories' do
      valid_categories = %w[land_acquisition studies construction_work equipment marketing legal administrative contingency]
      
      valid_categories.each do |category|
        budget_line.category = category
        expect(budget_line).to be_valid
      end
    end

    it 'rejects invalid categories' do
      expect {
        budget_line.category = 'invalid_category'
      }.to raise_error(ArgumentError, /'invalid_category' is not a valid category/)
    end
  end
end