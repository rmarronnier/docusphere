require 'rails_helper'

RSpec.describe Immo::Promo::PermitCondition, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:permit) { create(:immo_promo_permit, project: project) }
  let(:permit_condition) { create(:immo_promo_permit_condition, permit: permit) }

  describe 'associations' do
    it { is_expected.to belong_to(:permit).class_name('Immo::Promo::Permit') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:condition_type) }
  end

  describe 'enums' do
    it 'defines condition_type enum' do
      expect(permit_condition).to respond_to(:condition_type)
      expect(permit_condition).to respond_to(:status)
    end
  end

  describe '#is_fulfilled?' do
    it 'checks if condition is fulfilled' do
      permit_condition.update!(status: 'fulfilled')
      expect(permit_condition.is_fulfilled?).to be true
      
      permit_condition.update!(status: 'pending')
      expect(permit_condition.is_fulfilled?).to be false
    end
  end
end