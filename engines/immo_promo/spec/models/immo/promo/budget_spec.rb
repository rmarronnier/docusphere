require 'rails_helper'

RSpec.describe Immo::Promo::Budget, type: :model do
  let(:organization) { create(:organization) }
  let(:project_manager) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
  let(:budget) { create(:immo_promo_budget, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
    it { is_expected.to have_many(:budget_lines).class_name('Immo::Promo::BudgetLine').dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:budget_type).in_array(%w[initial revised final]) }
    it { is_expected.to validate_presence_of(:version) }
    
    it 'validates version uniqueness within project scope' do
      create(:immo_promo_budget, project: project, version: 1)
      duplicate_budget = build(:immo_promo_budget, project: project, version: 1)
      
      expect(duplicate_budget).not_to be_valid
      expect(duplicate_budget.errors[:version]).to include('has already been taken')
    end

    it 'allows same version for different projects' do
      other_project = create(:immo_promo_project, organization: organization)
      create(:immo_promo_budget, project: project, version: 1)
      other_budget = build(:immo_promo_budget, project: other_project, version: 1)
      
      expect(other_budget).to be_valid
    end
  end

  describe 'monetization' do
    it 'monetizes total_amount_cents' do
      expect(budget).to respond_to(:total_amount)
      expect(budget.total_amount).to be_a(Money)
    end

    it 'monetizes spent_amount_cents' do
      expect(budget).to respond_to(:spent_amount)
      budget.update!(spent_amount_cents: 100_000_00)
      expect(budget.spent_amount).to be_a(Money)
    end

    it 'allows nil spent_amount' do
      budget.update!(spent_amount_cents: nil)
      expect(budget.spent_amount).to be_nil
    end
  end

  describe 'enums' do
    it 'defines budget_type enum' do
      expect(budget).to respond_to(:budget_type)
      expect(Immo::Promo::Budget.budget_types).to eq({
        'initial' => 'initial',
        'revised' => 'revised',
        'final' => 'final'
      })
    end

    it 'allows setting budget_type' do
      budget.budget_type = 'revised'
      expect(budget.budget_type).to eq('revised')
      expect(budget).to be_revised
    end
  end

  describe 'scopes' do
    let!(:current_budget) { create(:immo_promo_budget, project: project, is_current: true) }
    let!(:old_budget) { create(:immo_promo_budget, project: project, is_current: false, version: 2) }
    let!(:revised_budget) { create(:immo_promo_budget, :revised, project: project, version: 3) }

    describe '.current' do
      it 'returns only current budgets' do
        current_budgets = Immo::Promo::Budget.current
        expect(current_budgets).to include(current_budget)
        expect(current_budgets).not_to include(old_budget)
      end
    end

    describe '.by_type' do
      it 'filters budgets by type' do
        initial_budgets = Immo::Promo::Budget.by_type('initial')
        expect(initial_budgets).to include(current_budget, old_budget)
        expect(initial_budgets).not_to include(revised_budget)

        revised_budgets = Immo::Promo::Budget.by_type('revised')
        expect(revised_budgets).to include(revised_budget)
        expect(revised_budgets).not_to include(current_budget, old_budget)
      end
    end
  end

  describe '#remaining_amount' do
    it 'calculates remaining amount' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: 30_000_00
      )
      
      expect(budget.remaining_amount).to eq(Money.new(70_000_00, 'EUR'))
    end

    it 'handles nil spent_amount' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: nil
      )
      
      expect(budget.remaining_amount).to eq(Money.new(100_000_00, 'EUR'))
    end
  end

  describe '#spending_percentage' do
    it 'calculates spending percentage' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: 25_000_00
      )
      
      expect(budget.spending_percentage).to eq(25.0)
    end

    it 'returns 0 when total amount is 0' do
      budget.update!(
        total_amount_cents: 0,
        spent_amount_cents: 10_000_00
      )
      
      expect(budget.spending_percentage).to eq(0)
    end

    it 'handles nil spent_amount' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: nil
      )
      
      expect(budget.spending_percentage).to eq(0)
    end
  end

  describe '#is_over_budget?' do
    it 'returns true when spending exceeds total' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: 120_000_00
      )
      
      expect(budget.is_over_budget?).to be true
    end

    it 'returns false when spending is within budget' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: 80_000_00
      )
      
      expect(budget.is_over_budget?).to be false
    end

    it 'returns false when spent_amount is nil' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: nil
      )
      
      expect(budget.is_over_budget?).to be false
    end
  end

  describe '#variance' do
    it 'calculates positive variance when over budget' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: 120_000_00
      )
      
      expect(budget.variance).to eq(Money.new(20_000_00, 'EUR'))
    end

    it 'calculates negative variance when under budget' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: 80_000_00
      )
      
      expect(budget.variance).to eq(Money.new(-20_000_00, 'EUR'))
    end

    it 'handles nil spent_amount' do
      budget.update!(
        total_amount_cents: 100_000_00,
        spent_amount_cents: nil
      )
      
      expect(budget.variance).to eq(Money.new(-100_000_00, 'EUR'))
    end
  end

  describe '#total_budget_lines_amount' do
    it 'sums all budget line amounts' do
      budget_line1 = create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 50_000_00)
      budget_line2 = create(:immo_promo_budget_line, budget: budget, planned_amount_cents: 30_000_00)
      
      expect(budget.total_budget_lines_amount).to eq(Money.new(80_000_00, 'EUR'))
    end

    it 'returns zero when no budget lines' do
      expect(budget.total_budget_lines_amount).to eq(Money.new(0, 'EUR'))
    end
  end

  describe '#budget_line_by_category' do
    it 'filters budget lines by category' do
      construction_line = create(:immo_promo_budget_line, budget: budget, category: 'construction_work')
      studies_line = create(:immo_promo_budget_line, budget: budget, category: 'studies')
      
      construction_lines = budget.budget_line_by_category('construction_work')
      expect(construction_lines).to include(construction_line)
      expect(construction_lines).not_to include(studies_line)
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(budget.class.audited_options).to be_present
    end

    it 'creates audit when budget is updated' do
      expect {
        budget.update!(name: 'Updated Budget Name')
      }.to change { budget.audits.count }.by(1)
    end
  end
end