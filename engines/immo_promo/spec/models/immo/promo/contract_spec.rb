require 'rails_helper'

RSpec.describe Immo::Promo::Contract, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
  let(:contract) { create(:immo_promo_contract, project: project, stakeholder: stakeholder) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
    it { is_expected.to belong_to(:stakeholder).class_name('Immo::Promo::Stakeholder') }
  end

  describe 'concerns' do
    it 'includes Schedulable' do
      expect(contract).to respond_to(:start_date)
      expect(contract).to respond_to(:end_date)
      expect(contract).to respond_to(:current?)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:reference) }
    # Les enums sont testés dans la section 'enums' ci-dessous

    it 'validates reference uniqueness within project scope' do
      create(:immo_promo_contract, project: project, stakeholder: stakeholder, reference: 'CONTRACT-001')
      duplicate_contract = build(:immo_promo_contract, project: project, stakeholder: stakeholder, reference: 'CONTRACT-001')
      
      expect(duplicate_contract).not_to be_valid
      expect(duplicate_contract.errors[:reference]).to include('est déjà utilisé')
    end
  end

  describe 'monetization' do
    it 'monetizes amount_cents' do
      expect(contract).to respond_to(:amount)
      expect(contract.amount).to be_a(Money)
    end

    it 'monetizes paid_amount_cents' do
      expect(contract).to respond_to(:paid_amount)
      contract.update!(paid_amount_cents: 100_000_00)
      expect(contract.paid_amount).to be_a(Money)
    end
  end

  describe 'enums' do
    it 'defines contract_type enum' do
      expect(contract).to respond_to(:contract_type)
      expect(Immo::Promo::Contract.contract_types.keys).to include('architecture', 'engineering', 'construction')
    end

    it 'defines status enum' do
      expect(contract).to respond_to(:status)
      expect(Immo::Promo::Contract.statuses.keys).to include('draft', 'signed', 'active')
    end
  end

  describe '#remaining_amount' do
    it 'calculates remaining amount to be paid' do
      contract.update!(
        amount_cents: 100_000_00,
        paid_amount_cents: 30_000_00
      )
      
      expect(contract.remaining_amount).to eq(Money.new(70_000_00, 'EUR'))
    end
  end

  describe '#payment_percentage' do
    it 'calculates payment percentage' do
      contract.update!(
        amount_cents: 100_000_00,
        paid_amount_cents: 25_000_00
      )
      
      expect(contract.payment_percentage).to eq(25.0)
    end
  end

  describe '#is_fully_paid?' do
    it 'returns true when fully paid' do
      contract.update!(
        amount_cents: 100_000_00,
        paid_amount_cents: 100_000_00
      )
      
      expect(contract.is_fully_paid?).to be true
    end

    it 'returns false when not fully paid' do
      contract.update!(
        amount_cents: 100_000_00,
        paid_amount_cents: 50_000_00
      )
      
      expect(contract.is_fully_paid?).to be false
    end
  end

  describe '#days_until_expiry' do
    it 'calculates days until contract expires' do
      contract.update!(end_date: 10.days.from_now)
      expect(contract.days_until_expiry).to eq(10)
    end

    it 'returns nil when no end_date' do
      contract.update!(end_date: nil)
      expect(contract.days_until_expiry).to be_nil
    end
  end

  describe '#is_expired?' do
    it 'returns true when contract has expired' do
      contract.update!(end_date: 1.day.ago)
      expect(contract.is_expired?).to be true
    end

    it 'returns false when contract is still valid' do
      contract.update!(end_date: 1.day.from_now)
      expect(contract.is_expired?).to be false
    end
  end

  describe 'scopes' do
    let!(:active_contract) { create(:immo_promo_contract, project: project, stakeholder: stakeholder, status: 'active') }
    let!(:signed_contract) { create(:immo_promo_contract, project: project, stakeholder: stakeholder, status: 'signed') }
    let!(:draft_contract) { create(:immo_promo_contract, project: project, stakeholder: stakeholder, status: 'draft') }

    describe '.active_contracts' do
      it 'returns signed and active contracts' do
        active_contracts = Immo::Promo::Contract.active_contracts
        expect(active_contracts).to include(active_contract, signed_contract)
        expect(active_contracts).not_to include(draft_contract)
      end
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(contract.class.audited_options).to be_present
    end
  end
end