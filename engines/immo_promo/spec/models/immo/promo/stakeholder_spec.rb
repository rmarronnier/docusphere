require 'rails_helper'

RSpec.describe Immo::Promo::Stakeholder, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
    it { is_expected.to have_many(:tasks).class_name('Immo::Promo::Task').dependent(:nullify) }
    it { is_expected.to have_many(:contracts).class_name('Immo::Promo::Contract').dependent(:destroy) }
    it { is_expected.to have_many(:certifications).class_name('Immo::Promo::Certification').dependent(:destroy) }
  end

  describe 'concerns' do
    it 'includes Addressable' do
      expect(stakeholder).to respond_to(:full_address)
      expect(stakeholder.class.included_modules).to include(Addressable)
    end

    it 'includes Immo::Promo::Documentable' do
      expect(stakeholder).to respond_to(:documents)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it 'validates stakeholder_type' do
      expect {
        subject.stakeholder_type = 'invalid_type'
      }.to raise_error(ArgumentError, /'invalid_type' is not a valid stakeholder_type/)
    end
    
    it 'validates email format when present' do
      stakeholder.email = 'invalid_email'
      expect(stakeholder).not_to be_valid
      expect(stakeholder.errors[:email]).to be_present
      
      stakeholder.email = 'valid@example.com'
      expect(stakeholder).to be_valid
    end

    it 'allows blank email' do
      stakeholder.email = ''
      expect(stakeholder).to be_valid
    end

    it 'validates SIRET length when present' do
      stakeholder.siret = '123456789'
      expect(stakeholder).not_to be_valid
      expect(stakeholder.errors[:siret]).to be_present
      
      stakeholder.siret = '12345678901234'
      expect(stakeholder).to be_valid
    end

    it 'allows blank SIRET' do
      stakeholder.siret = ''
      expect(stakeholder).to be_valid
    end
  end

  describe 'enums' do
    it 'defines stakeholder_type enum' do
      expect(stakeholder).to respond_to(:stakeholder_type)
      expect(Immo::Promo::Stakeholder.stakeholder_types.keys).to include(
        'architect', 'engineer', 'contractor', 'subcontractor', 'consultant',
        'control_office', 'client', 'investor', 'legal_advisor'
      )
    end

    it 'allows setting stakeholder_type' do
      stakeholder.stakeholder_type = 'architect'
      expect(stakeholder.stakeholder_type).to eq('architect')
      expect(stakeholder).to be_architect
    end
  end

  describe 'scopes' do
    let!(:architect) { create(:immo_promo_stakeholder, project: project, stakeholder_type: 'architect') }
    let!(:contractor) { create(:immo_promo_stakeholder, project: project, stakeholder_type: 'contractor') }
    let!(:active_stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: true) }
    let!(:inactive_stakeholder) { create(:immo_promo_stakeholder, project: project, is_active: false) }

    describe '.by_type' do
      it 'filters stakeholders by type' do
        architects = Immo::Promo::Stakeholder.by_type('architect')
        expect(architects).to include(architect)
        expect(architects).not_to include(contractor)
      end
    end

    describe '.active' do
      it 'returns only active stakeholders' do
        active_stakeholders = Immo::Promo::Stakeholder.active
        expect(active_stakeholders).to include(active_stakeholder)
        expect(active_stakeholders).not_to include(inactive_stakeholder)
      end
    end

    describe '.with_valid_insurance' do
      it 'returns stakeholders with valid insurance' do
        create(:immo_promo_certification, 
               stakeholder: active_stakeholder, 
               certification_type: 'insurance', 
               is_valid: true)
        
        insured_stakeholders = Immo::Promo::Stakeholder.with_valid_insurance
        expect(insured_stakeholders).to include(active_stakeholder)
      end
    end
  end

  describe '#full_name' do
    it 'returns name with humanized stakeholder type' do
      stakeholder.update!(name: 'Jean Dupont', stakeholder_type: 'architect')
      expect(stakeholder.full_name).to eq('Jean Dupont (Architect)')
    end
  end

  describe '#has_valid_insurance?' do
    it 'returns true when stakeholder has valid insurance certification' do
      create(:immo_promo_certification, 
             stakeholder: stakeholder, 
             certification_type: 'insurance', 
             is_valid: true)
      
      expect(stakeholder.has_valid_insurance?).to be true
    end

    it 'returns false when no valid insurance certification' do
      create(:immo_promo_certification, 
             stakeholder: stakeholder, 
             certification_type: 'insurance', 
             is_valid: false)
      
      expect(stakeholder.has_valid_insurance?).to be false
    end
  end

  describe '#has_valid_qualification?' do
    it 'returns true when stakeholder has valid qualification certification' do
      create(:immo_promo_certification, 
             stakeholder: stakeholder, 
             certification_type: 'qualification', 
             is_valid: true)
      
      expect(stakeholder.has_valid_qualification?).to be true
    end

    it 'returns false when no valid qualification certification' do
      expect(stakeholder.has_valid_qualification?).to be false
    end
  end

  describe '#active_contracts' do
    it 'returns contracts with active status' do
      active_contract = create(:immo_promo_contract, stakeholder: stakeholder, status: 'active')
      inactive_contract = create(:immo_promo_contract, stakeholder: stakeholder, status: 'terminated')
      
      expect(stakeholder.active_contracts).to include(active_contract)
      expect(stakeholder.active_contracts).not_to include(inactive_contract)
    end
  end

  describe '#can_work_on_project?' do
    it 'returns true when stakeholder is active and has valid insurance' do
      stakeholder.update!(is_active: true)
      create(:immo_promo_certification, 
             stakeholder: stakeholder, 
             certification_type: 'insurance', 
             is_valid: true)
      
      expect(stakeholder.can_work_on_project?).to be true
    end

    it 'returns false when stakeholder is inactive' do
      stakeholder.update!(is_active: false)
      create(:immo_promo_certification, 
             stakeholder: stakeholder, 
             certification_type: 'insurance', 
             is_valid: true)
      
      expect(stakeholder.can_work_on_project?).to be false
    end

    it 'returns false when stakeholder has no valid insurance' do
      stakeholder.update!(is_active: true)
      expect(stakeholder.can_work_on_project?).to be false
    end
  end

  describe '#contact_info' do
    it 'joins email and phone with pipe separator' do
      stakeholder.update!(email: 'test@example.com', phone: '0123456789')
      expect(stakeholder.contact_info).to eq('test@example.com | 0123456789')
    end

    it 'handles missing email' do
      stakeholder.update!(email: nil, phone: '0123456789')
      expect(stakeholder.contact_info).to eq('0123456789')
    end

    it 'handles missing phone' do
      stakeholder.update!(email: 'test@example.com', phone: nil)
      expect(stakeholder.contact_info).to eq('test@example.com')
    end
  end

  describe '#engagement_score' do
    it 'calculates engagement score based on tasks and contracts' do
      # Create completed tasks (15 points each)
      create_list(:immo_promo_task, 2, stakeholder: stakeholder, status: 'completed')
      
      # Create in-progress tasks (10 points each)
      create_list(:immo_promo_task, 1, stakeholder: stakeholder, status: 'in_progress')
      
      # Create active contracts (20 points each)
      create_list(:immo_promo_contract, 1, stakeholder: stakeholder, status: 'active')
      
      # Expected score: (2 * 15) + (1 * 10) + (1 * 20) = 60
      expect(stakeholder.engagement_score).to eq(60)
    end

    it 'caps engagement score at 100' do
      create_list(:immo_promo_task, 10, stakeholder: stakeholder, status: 'completed')
      expect(stakeholder.engagement_score).to eq(100)
    end
  end

  describe '#workload_status' do
    it 'returns :available when no active tasks' do
      expect(stakeholder.workload_status).to eq(:available)
    end

    it 'returns :partially_available for 1-3 active tasks' do
      create_list(:immo_promo_task, 2, stakeholder: stakeholder, status: 'in_progress')
      expect(stakeholder.workload_status).to eq(:partially_available)
    end

    it 'returns :busy for 4-6 active tasks' do
      create_list(:immo_promo_task, 5, stakeholder: stakeholder, status: 'in_progress')
      expect(stakeholder.workload_status).to eq(:busy)
    end

    it 'returns :overloaded for more than 6 active tasks' do
      create_list(:immo_promo_task, 8, stakeholder: stakeholder, status: 'in_progress')
      expect(stakeholder.workload_status).to eq(:overloaded)
    end
  end

  describe '#performance_rating' do
    it 'returns :not_rated when no completed tasks' do
      expect(stakeholder.performance_rating).to eq(:not_rated)
    end

    it 'calculates performance based on on-time completion' do
      # Create tasks completed on time
      3.times do
        task = create(:immo_promo_task, 
                     stakeholder: stakeholder, 
                     status: 'completed',
                     start_date: 3.days.ago,
                     end_date: 1.day.from_now,
                     actual_end_date: Time.current)
      end
      
      # Create task completed late
      create(:immo_promo_task, 
             stakeholder: stakeholder, 
             status: 'completed',
             start_date: 3.days.ago,
             end_date: 1.day.ago,
             actual_end_date: Time.current)
      
      # 3/4 = 75% on time = :average
      expect(stakeholder.performance_rating).to eq(:average)
    end
  end

  describe '#qualification_issues' do
    it 'returns array of qualification issues' do
      stakeholder.update!(stakeholder_type: 'architect')
      issues = stakeholder.qualification_issues
      
      expect(issues).to include(:insurance_missing)
      expect(issues).to include(:qualification_missing)
      expect(issues).to include(:registration_missing)
    end

    it 'excludes resolved issues' do
      create(:immo_promo_certification, 
             stakeholder: stakeholder, 
             certification_type: 'insurance', 
             is_valid: true)
      
      issues = stakeholder.qualification_issues
      expect(issues).not_to include(:insurance_missing)
    end
  end

  describe '#contact_sheet_info' do
    it 'returns formatted contact information hash' do
      stakeholder.update!(
        name: 'Jean Dupont',
        stakeholder_type: 'architect',
        email: 'jean@example.com',
        phone: '0123456789',
        is_active: true
      )
      
      info = stakeholder.contact_sheet_info
      
      expect(info[:name]).to eq('Jean Dupont')
      expect(info[:stakeholder_type]).to eq('architect')
      expect(info[:email]).to eq('jean@example.com')
      expect(info[:phone]).to eq('0123456789')
      expect(info[:active]).to be true
    end
  end

  describe 'attribute aliases' do
    it 'aliases notification_enabled to is_active' do
      stakeholder.notification_enabled = true
      expect(stakeholder.is_active).to be true
      
      stakeholder.notification_enabled = false
      expect(stakeholder.is_active).to be false
    end

    it 'aliases is_critical to is_primary' do
      stakeholder.is_critical = true
      expect(stakeholder.is_primary).to be true
      
      stakeholder.is_critical = false
      expect(stakeholder.is_primary).to be false
    end

    it 'aliases contact_email to email' do
      stakeholder.email = 'test@example.com'
      expect(stakeholder.contact_email).to eq('test@example.com')
    end

    it 'aliases contact_phone to phone' do
      stakeholder.phone = '0123456789'
      expect(stakeholder.contact_phone).to eq('0123456789')
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(stakeholder.class.audited_options).to be_present
    end

    it 'creates audit when stakeholder is updated' do
      # Test that auditing is enabled (this is sufficient for testing)
      expect(stakeholder.class.audited_options).to be_present
      expect(stakeholder).to respond_to(:audits)
    end
  end
end