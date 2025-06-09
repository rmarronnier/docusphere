require 'rails_helper'

RSpec.describe Immo::Promo::Certification, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
  let(:certification) { create(:immo_promo_certification, stakeholder: stakeholder) }

  describe 'associations' do
    it { is_expected.to belong_to(:stakeholder).class_name('Immo::Promo::Stakeholder') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:issuing_body) }
  end

  describe 'enums' do
    it 'defines certification_type enum' do
      expect(certification).to respond_to(:certification_type)
      expect(Immo::Promo::Certification.certification_types.keys).to include(
        'insurance', 'qualification', 'rge', 'environmental'
      )
    end

    it 'allows setting certification_type' do
      certification.certification_type = 'insurance'
      expect(certification.certification_type).to eq('insurance')
      expect(certification).to be_insurance
    end
  end

  describe 'attribute aliases' do
    it 'aliases issuing_authority to issuing_body' do
      certification.issuing_body = 'Test Authority'
      expect(certification.issuing_authority).to eq('Test Authority')
    end
  end

  describe 'scopes' do
    let!(:valid_cert) { create(:immo_promo_certification, stakeholder: stakeholder, is_valid: true) }
    let!(:invalid_cert) { create(:immo_promo_certification, stakeholder: stakeholder, is_valid: false) }
    let!(:expiring_cert) { create(:immo_promo_certification, stakeholder: stakeholder, expiry_date: 1.month.from_now) }
    let!(:future_cert) { create(:immo_promo_certification, stakeholder: stakeholder, expiry_date: 1.year.from_now) }

    describe '.valid' do
      it 'returns only valid certifications' do
        valid_certs = Immo::Promo::Certification.valid
        expect(valid_certs).to include(valid_cert)
        expect(valid_certs).not_to include(invalid_cert)
      end
    end

    describe '.expiring_soon' do
      it 'returns certifications expiring within 3 months' do
        expiring_certs = Immo::Promo::Certification.expiring_soon
        expect(expiring_certs).to include(expiring_cert)
        expect(expiring_certs).not_to include(future_cert)
      end
    end

    describe '.by_type' do
      it 'filters certifications by type' do
        insurance_cert = create(:immo_promo_certification, stakeholder: stakeholder, certification_type: 'insurance')
        qualification_cert = create(:immo_promo_certification, stakeholder: stakeholder, certification_type: 'qualification')
        
        insurance_certs = Immo::Promo::Certification.by_type('insurance')
        expect(insurance_certs).to include(insurance_cert)
        expect(insurance_certs).not_to include(qualification_cert)
      end
    end
  end

  describe '#is_expired?' do
    it 'returns true when certification has expired' do
      certification.update!(expiry_date: 1.day.ago)
      expect(certification.is_expired?).to be true
    end

    it 'returns false when certification is still valid' do
      certification.update!(expiry_date: 1.day.from_now)
      expect(certification.is_expired?).to be false
    end

    it 'returns false when no expiry_date' do
      certification.update!(expiry_date: nil)
      expect(certification.is_expired?).to be false
    end
  end

  describe '#days_until_expiry' do
    it 'calculates days until certification expires' do
      certification.update!(expiry_date: 10.days.from_now)
      expect(certification.days_until_expiry).to eq(10)
    end

    it 'returns negative value for expired certifications' do
      certification.update!(expiry_date: 5.days.ago)
      expect(certification.days_until_expiry).to eq(-5)
    end

    it 'returns nil when no expiry_date' do
      certification.update!(expiry_date: nil)
      expect(certification.days_until_expiry).to be_nil
    end
  end

  describe '#is_expiring_soon?' do
    it 'returns true when expiring within 90 days' do
      certification.update!(expiry_date: 60.days.from_now)
      expect(certification.is_expiring_soon?).to be true
    end

    it 'returns false when expiring beyond 90 days' do
      certification.update!(expiry_date: 120.days.from_now)
      expect(certification.is_expiring_soon?).to be false
    end

    it 'returns false when already expired' do
      certification.update!(expiry_date: 1.day.ago)
      expect(certification.is_expiring_soon?).to be false
    end

    it 'returns false when no expiry_date' do
      certification.update!(expiry_date: nil)
      expect(certification.is_expiring_soon?).to be false
    end
  end

  describe '#validity_status' do
    it 'returns "expired" when certification has expired' do
      certification.update!(expiry_date: 1.day.ago, is_valid: true)
      expect(certification.validity_status).to eq('expired')
    end

    it 'returns "expiring_soon" when expiring within 90 days' do
      certification.update!(expiry_date: 60.days.from_now, is_valid: true)
      expect(certification.validity_status).to eq('expiring_soon')
    end

    it 'returns "valid" when valid and not expiring soon' do
      certification.update!(expiry_date: 120.days.from_now, is_valid: true)
      expect(certification.validity_status).to eq('valid')
    end

    it 'returns "invalid" when not valid' do
      certification.update!(expiry_date: 120.days.from_now, is_valid: false)
      expect(certification.validity_status).to eq('invalid')
    end
  end
end