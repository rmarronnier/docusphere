require 'rails_helper'

RSpec.describe Immo::Promo::Permit, type: :model do
  let(:project) { create(:immo_promo_project) }
  let(:permit) { create(:immo_promo_permit, project: project) }

  describe 'associations' do
    it { should belong_to(:project).class_name('Immo::Promo::Project') }
    it { should have_many(:permit_conditions).class_name('Immo::Promo::PermitCondition').dependent(:destroy) }
    it { should have_many_attached(:permit_documents) }
    it { should have_many_attached(:response_documents) }
  end

  describe 'validations' do
    it { should validate_presence_of(:permit_number) }
    it { should validate_uniqueness_of(:permit_number).scoped_to(:project_id) }
    it { should validate_presence_of(:permit_type) }
    it { should validate_presence_of(:issuing_authority) }
    
    # Enum validations are tested in the 'enums' section below
  end

  describe 'enums' do
    it { should define_enum_for(:permit_type).backed_by_column_of_type(:string).with_values(
      urban_planning: 'urban_planning',
      construction: 'construction',
      demolition: 'demolition',
      environmental: 'environmental',
      modification: 'modification',
      declaration: 'declaration'
    ) }

    it { should define_enum_for(:status).backed_by_column_of_type(:string).with_values(
      draft: 'draft',
      submitted: 'submitted',
      under_review: 'under_review',
      additional_info_requested: 'additional_info_requested',
      approved: 'approved',
      denied: 'denied',
      appeal: 'appeal'
    ) }
  end

  # No monetized attributes in Permit model

  describe 'scopes' do
    describe '.pending' do
      it 'returns permits not yet approved' do
        pending_permit = create(:immo_promo_permit, status: 'submitted')
        approved_permit = create(:immo_promo_permit, status: 'approved')

        expect(Immo::Promo::Permit.pending).to include(pending_permit)
        expect(Immo::Promo::Permit.pending).not_to include(approved_permit)
      end
    end

    describe '.approved' do
      it 'returns approved permits' do
        approved_permit = create(:immo_promo_permit, status: 'approved')
        pending_permit = create(:immo_promo_permit, status: 'submitted')

        expect(Immo::Promo::Permit.approved).to include(approved_permit)
        expect(Immo::Promo::Permit.approved).not_to include(pending_permit)
      end
    end

    describe '.critical' do
      it 'returns construction and urban planning permits' do
        construction_permit = create(:immo_promo_permit, permit_type: 'construction')
        urban_planning_permit = create(:immo_promo_permit, permit_type: 'urban_planning')
        environmental_permit = create(:immo_promo_permit, permit_type: 'environmental')

        expect(Immo::Promo::Permit.critical).to include(construction_permit, urban_planning_permit)
        expect(Immo::Promo::Permit.critical).not_to include(environmental_permit)
      end
    end

    describe '.expiring_soon' do
      it 'returns permits expiring within 30 days' do
        expiring_permit = create(:immo_promo_permit, status: 'approved', expiry_date: 15.days.from_now)
        not_expiring_permit = create(:immo_promo_permit, status: 'approved', expiry_date: 45.days.from_now)
        # Only test with permits that have expiry dates since end_date is required by Schedulable
        expect(Immo::Promo::Permit.expiring_soon(30)).to include(expiring_permit)
        expect(Immo::Promo::Permit.expiring_soon(30)).not_to include(not_expiring_permit)
      end
    end
  end

  describe '#approved?' do
    it 'returns true when status is approved' do
      permit.status = 'approved'
      expect(permit.approved?).to be_truthy
    end

    it 'returns false for other statuses' do
      permit.status = 'submitted'
      expect(permit.approved?).to be_falsey
    end
  end


  describe '#is_expired?' do
    context 'without expiry date' do
      it 'returns false' do
        permit.expiry_date = nil
        expect(permit.is_expired?).to be_falsey
      end
    end

    context 'with future expiry date' do
      it 'returns false' do
        permit.expiry_date = 1.day.from_now
        expect(permit.is_expired?).to be_falsey
      end
    end

    context 'with past expiry date' do
      it 'returns true' do
        permit.expiry_date = 1.day.ago
        expect(permit.is_expired?).to be_truthy
      end
    end
  end

  describe '#days_until_expiry' do
    it 'returns days until expiry' do
      permit.expiry_date = 10.days.from_now.to_date
      expect(permit.days_until_expiry).to eq(10)
    end

    it 'returns nil when no expiry date' do
      permit.expiry_date = nil
      expect(permit.days_until_expiry).to be_nil
    end

    it 'returns negative days when expired' do
      permit.expiry_date = 5.days.ago.to_date
      expect(permit.days_until_expiry).to eq(-5)
    end
  end

  describe '#processing_time_days' do
    context 'when approved' do
      it 'calculates days between submission and approval' do
        permit.submitted_date = 10.days.ago
        permit.approved_date = 3.days.ago
        expect(permit.processing_time_days).to eq(7)
      end
    end

    context 'when still pending' do
      it 'calculates days since submission' do
        permit.submitted_date = 5.days.ago
        permit.approved_date = nil
        expect(permit.processing_time_days).to eq(5)
      end
    end

    context 'when not submitted' do
      it 'returns 0' do
        permit.submitted_date = nil
        expect(permit.processing_time_days).to eq(0)
      end
    end
  end

  describe '#has_conditions?' do
    it 'returns true when conditions exist' do
      create(:immo_promo_permit_condition, permit: permit)
      expect(permit.has_conditions?).to be_truthy
    end

    it 'returns false when no conditions' do
      expect(permit.has_conditions?).to be_falsey
    end
  end

  describe '#all_conditions_met?' do
    it 'returns true when all conditions are met' do
      create(:immo_promo_permit_condition, permit: permit, status: 'met')
      create(:immo_promo_permit_condition, permit: permit, status: 'met')
      expect(permit.all_conditions_met?).to be_truthy
    end

    it 'returns false when some conditions are not met' do
      create(:immo_promo_permit_condition, permit: permit, status: 'met')
      create(:immo_promo_permit_condition, permit: permit, status: 'pending')
      expect(permit.all_conditions_met?).to be_falsey
    end

    it 'returns true when no conditions' do
      expect(permit.all_conditions_met?).to be_truthy
    end
  end
end