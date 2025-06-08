require 'rails_helper'

RSpec.describe Immo::Promo::PermitTrackerService do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:service) { described_class.new(project) }

  describe '#initialize' do
    it 'sets the project' do
      expect(service.instance_variable_get(:@project)).to eq(project)
    end
  end

  describe '#track_permit_status' do
    let!(:draft_permit) { create(:immo_promo_permit, project: project, status: 'draft') }
    let!(:submitted_permit) { create(:immo_promo_permit, project: project, status: 'submitted') }
    let!(:approved_permit) { create(:immo_promo_permit, project: project, status: 'approved') }

    it 'returns status summary' do
      summary = service.track_permit_status
      
      expect(summary[:total]).to eq(3)
      expect(summary[:by_status][:draft]).to eq(1)
      expect(summary[:by_status][:submitted]).to eq(1)
      expect(summary[:by_status][:approved]).to eq(1)
    end

    it 'calculates approval rate' do
      summary = service.track_permit_status
      expect(summary[:approval_rate]).to eq(33.33)
    end

    it 'identifies pending permits' do
      summary = service.track_permit_status
      expect(summary[:pending]).to include(draft_permit, submitted_permit)
      expect(summary[:pending]).not_to include(approved_permit)
    end
  end

  describe '#check_expiring_permits' do
    let!(:expiring_soon) { create(:immo_promo_permit, project: project, status: 'approved', expiry_date: 15.days.from_now) }
    let!(:expiring_later) { create(:immo_promo_permit, project: project, status: 'approved', expiry_date: 45.days.from_now) }
    let!(:expired) { create(:immo_promo_permit, project: project, status: 'approved', submitted_date: 1.year.ago, expiry_date: 1.day.ago) }
    let!(:no_expiry) { create(:immo_promo_permit, project: project, status: 'approved', expiry_date: nil) }

    it 'returns permits expiring within threshold' do
      permits = service.check_expiring_permits(days: 30)
      
      expect(permits).to include(expiring_soon)
      expect(permits).not_to include(expiring_later, expired, no_expiry)
    end

    it 'uses default 30 days threshold' do
      permits = service.check_expiring_permits
      
      expect(permits).to include(expiring_soon)
      expect(permits).not_to include(expiring_later)
    end

    it 'orders by expiry date' do
      another_expiring = create(:immo_promo_permit, project: project, status: 'approved', expiry_date: 5.days.from_now)
      
      permits = service.check_expiring_permits
      
      expect(permits.first).to eq(another_expiring)
      expect(permits.second).to eq(expiring_soon)
    end
  end

  describe '#calculate_processing_times' do
    before do
      create(:immo_promo_permit, 
             project: project,
             permit_type: 'construction',
             status: 'approved',
             submitted_date: 30.days.ago,
             approved_date: 10.days.ago)
      
      create(:immo_promo_permit,
             project: project, 
             permit_type: 'construction',
             status: 'approved',
             submitted_date: 25.days.ago,
             approved_date: 5.days.ago)
      
      create(:immo_promo_permit,
             project: project,
             permit_type: 'environmental',
             status: 'approved',
             submitted_date: 20.days.ago,
             approved_date: 15.days.ago)
    end

    it 'calculates average processing time by type' do
      times = service.calculate_processing_times
      
      expect(times[:by_type][:construction][:average_days]).to eq(20.0)
      expect(times[:by_type][:construction][:count]).to eq(2)
      
      expect(times[:by_type][:environmental][:average_days]).to eq(5.0)
      expect(times[:by_type][:environmental][:count]).to eq(1)
    end

    it 'calculates overall average' do
      times = service.calculate_processing_times
      expect(times[:overall_average]).to eq(15.0)
    end

    it 'identifies fastest and slowest types' do
      times = service.calculate_processing_times
      
      expect(times[:fastest_type]).to eq('environmental')
      expect(times[:slowest_type]).to eq('construction')
    end
  end

  describe '#critical_permits_status' do
    let!(:construction_approved) { create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'approved') }
    let!(:environmental_approved) { create(:immo_promo_permit, project: project, permit_type: 'environmental', status: 'approved') }

    it 'identifies critical permits' do
      status = service.critical_permits_status
      
      expect(status[:critical_permits]).to include(construction_approved)
      expect(status[:critical_permits]).not_to include(environmental_approved)
    end

    it 'calculates readiness for construction' do
      status = service.critical_permits_status
      
      expect(status[:ready_for_construction]).to be false
      expect(status[:missing_permits]).to include('urban_planning')
    end

    context 'when all critical permits approved' do
      before do
        create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved')
      end

      it 'indicates construction readiness' do
        status = service.critical_permits_status
        
        expect(status[:ready_for_construction]).to be true
        expect(status[:missing_permits]).to be_empty
      end
    end
  end

  describe '#generate_permit_timeline' do
    let!(:permit1) { create(:immo_promo_permit, project: project, submitted_date: 3.months.ago, approved_date: 2.months.ago) }
    let!(:permit2) { create(:immo_promo_permit, project: project, submitted_date: 2.months.ago, approved_date: nil) }

    it 'generates timeline events' do
      timeline = service.generate_permit_timeline
      
      expect(timeline).to be_an(Array)
      expect(timeline.size).to be >= 2
    end

    it 'includes submission events' do
      timeline = service.generate_permit_timeline
      
      submission_events = timeline.select { |e| e[:type] == 'submission' }
      expect(submission_events.size).to eq(2)
    end

    it 'includes approval events' do
      timeline = service.generate_permit_timeline
      
      approval_events = timeline.select { |e| e[:type] == 'approval' }
      expect(approval_events.size).to eq(1)
    end

    it 'orders events chronologically' do
      timeline = service.generate_permit_timeline
      dates = timeline.map { |e| e[:date] }.compact
      
      expect(dates).to eq(dates.sort)
    end
  end

  describe '#notify_permit_updates' do
    let(:permit) { create(:immo_promo_permit, project: project) }

    it 'sends notification for status change' do
      expect {
        service.notify_permit_updates(permit, 'submitted', 'approved')
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'creates notification record' do
      expect {
        service.notify_permit_updates(permit, 'submitted', 'approved')
      }.to change { Notification.count }.by(1)
    end

    it 'includes relevant information in notification' do
      service.notify_permit_updates(permit, 'submitted', 'approved')
      
      notification = Notification.last
      expect(notification.title).to include(permit.permit_number)
      expect(notification.message).to include('approved')
    end
  end

  describe '#compliance_check' do
    let!(:permit1) { create(:immo_promo_permit, project: project, status: 'approved') }
    let!(:permit2) { create(:immo_promo_permit, project: project, status: 'approved') }

    context 'when all conditions are met' do
      before do
        create(:immo_promo_permit_condition, permit: permit1, is_fulfilled: true)
        create(:immo_promo_permit_condition, permit: permit2, is_fulfilled: true)
      end

      it 'returns compliant status' do
        check = service.compliance_check
        
        expect(check[:compliant]).to be true
        expect(check[:issues]).to be_empty
      end
    end

    context 'when conditions are not met' do
      let!(:unmet_condition) { create(:immo_promo_permit_condition, permit: permit1, is_fulfilled: false, description: 'Safety inspection') }

      it 'identifies compliance issues' do
        check = service.compliance_check
        
        expect(check[:compliant]).to be false
        expect(check[:issues]).to include(hash_including(
          permit: permit1,
          unmet_conditions: [unmet_condition]
        ))
      end
    end

    context 'when permits are expired' do
      before do
        permit1.update(expiry_date: 1.day.ago)
      end

      it 'flags expired permits' do
        check = service.compliance_check
        
        expect(check[:compliant]).to be false
        expect(check[:expired_permits]).to include(permit1)
      end
    end
  end

  describe '#generate_permit_report' do
    let(:report) { service.generate_permit_report }

    before do
      create_list(:immo_promo_permit, 3, project: project, status: 'approved')
      create_list(:immo_promo_permit, 2, project: project, status: 'submitted')
    end

    it 'includes summary statistics' do
      expect(report[:status_summary]).to include(
        :total,
        :by_status,
        :approval_rate,
        :pending
      )
    end

    it 'includes processing time analysis' do
      expect(report[:processing_times]).to be_present
    end

    it 'includes compliance status' do
      expect(report[:compliance]).to be_present
    end

    it 'includes critical permits status' do
      expect(report[:critical_permits]).to be_present
    end

    it 'includes generated timestamp' do
      expect(report[:generated_at]).to be_a(Time)
    end
  end
end