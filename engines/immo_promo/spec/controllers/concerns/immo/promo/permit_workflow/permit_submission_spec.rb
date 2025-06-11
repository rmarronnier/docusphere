require 'rails_helper'

RSpec.describe Immo::Promo::PermitWorkflow::PermitSubmission, type: :concern do

  let(:controller_class) do
    Class.new(ApplicationController) do
      include Immo::Promo::PermitWorkflow::PermitSubmission
      
      attr_accessor :project, :current_user, :params, :flash
      
      def initialize(project = nil, user = nil)
        @project = project
        @current_user = user
        @params = {}
        @flash = {}
      end
      
      def redirect_to(path)
        @redirect_path = path
      end
      
      def redirect_back(options = {})
        @redirect_path = options[:fallback_location]
      end
      
      def immo_promo_engine
        double('engine', 
          project_permit_workflow_dashboard_path: '/dashboard',
          project_permit_workflow_compliance_checklist_path: '/compliance'
        )
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:permit) { create(:immo_promo_permit, project: project, permit_type: 'construction') }
  let(:controller) { controller_class.new(project, user) }

  before do
    controller.params = { permit_id: permit.id }
  end

  describe '#submit_permit' do
    context 'when permit can be submitted' do
      before do
        allow(permit).to receive(:can_be_submitted?).and_return(true)
        allow(controller).to receive(:submit_permit_application).and_return({ success: true })
      end

      it 'submits the permit successfully' do
        controller.submit_permit
        
        permit.reload
        expect(permit.status).to eq('submitted')
        expect(permit.submission_date).to eq(Date.current)
        expect(permit.submitted_by).to eq(user)
        expect(controller.flash[:success]).to include('soumise avec succès')
      end
    end

    context 'when permit cannot be submitted' do
      before do
        allow(permit).to receive(:can_be_submitted?).and_return(false)
      end

      it 'shows error message' do
        controller.submit_permit
        
        expect(controller.flash[:error]).to eq("Ce permis ne peut pas être soumis dans son état actuel")
        expect(permit.status).not_to eq('submitted')
      end
    end

    context 'when submission fails' do
      before do
        allow(permit).to receive(:can_be_submitted?).and_return(true)
        allow(controller).to receive(:submit_permit_application).and_return({ 
          success: false, 
          error: 'Service indisponible' 
        })
      end

      it 'shows submission error' do
        controller.submit_permit
        
        expect(controller.flash[:error]).to eq('Service indisponible')
        expect(permit.status).not_to eq('submitted')
      end
    end
  end

  describe '#track_response' do
    context 'when status has changed' do
      before do
        allow(controller).to receive(:check_permit_status_with_administration).and_return({
          status_changed: true,
          new_status: 'approved',
          response_date: Date.current,
          reference: 'REF-123'
        })
      end

      it 'updates permit status' do
        controller.track_response
        
        permit.reload
        expect(permit.status).to eq('approved')
        expect(permit.response_date).to eq(Date.current)
        expect(permit.administration_reference).to eq('REF-123')
        expect(controller.flash[:success]).to include('Statut du permis mis à jour')
      end
    end

    context 'when no update is available' do
      before do
        allow(controller).to receive(:check_permit_status_with_administration).and_return({
          status_changed: false
        })
      end

      it 'shows info message' do
        controller.track_response
        
        expect(controller.flash[:info]).to eq('Aucune mise à jour disponible pour ce permis')
      end
    end
  end

  describe '#extend_permit' do
    context 'when permit can be extended' do
      before do
        allow(permit).to receive(:can_be_extended?).and_return(true)
        allow(controller).to receive(:request_permit_extension).and_return({ success: true })
        controller.params.merge!(extension_months: '6', justification: 'Retard chantier')
      end

      it 'requests permit extension' do
        controller.extend_permit
        
        permit.reload
        expect(permit.extension_status).to eq('requested')
        expect(permit.extension_requested_at).to eq(Date.current)
        expect(permit.extension_justification).to eq('Retard chantier')
        expect(controller.flash[:success]).to eq('Demande de prolongation soumise')
      end
    end

    context 'when permit cannot be extended' do
      before do
        allow(permit).to receive(:can_be_extended?).and_return(false)
      end

      it 'shows error message' do
        controller.extend_permit
        
        expect(controller.flash[:error]).to eq('Ce permis ne peut pas être prolongé')
        expect(permit.extension_status).to be_nil
      end
    end
  end

  describe '#alert_administration' do
    before do
      controller.params.merge!(alert_type: 'delay_inquiry')
    end

    context 'for delay inquiry' do
      before do
        allow(controller).to receive(:send_delay_inquiry).and_return({ success: true })
        allow(controller).to receive(:log_permit_action)
      end

      it 'sends delay inquiry' do
        controller.alert_administration
        
        expect(controller.flash[:success]).to eq('Demande de suivi envoyée à l\'administration')
        expect(controller).to have_received(:log_permit_action).with(permit, 'delay_inquiry', user)
      end
    end

    context 'for urgent request' do
      before do
        controller.params.merge!(alert_type: 'urgent_request', urgency_justification: 'Délai critique')
        allow(controller).to receive(:send_urgent_request).and_return({ success: true })
        allow(controller).to receive(:log_permit_action)
      end

      it 'sends urgent request' do
        controller.alert_administration
        
        expect(controller.flash[:success]).to eq('Demande urgente transmise')
      end
    end

    context 'for appeal request' do
      before do
        controller.params.merge!(alert_type: 'appeal_request', appeal_grounds: 'Décision contestable')
        allow(controller).to receive(:initiate_appeal_process).and_return({ success: true })
        allow(controller).to receive(:log_permit_action)
      end

      it 'initiates appeal process' do
        controller.alert_administration
        
        expect(controller.flash[:success]).to eq('Procédure de recours initiée')
      end
    end

    context 'for unknown alert type' do
      before do
        controller.params.merge!(alert_type: 'unknown_type')
      end

      it 'shows error for unknown type' do
        controller.alert_administration
        
        expect(controller.flash[:error]).to eq('Type d\'alerte non reconnu')
      end
    end
  end

  describe '#upcoming_permit_deadlines' do
    let!(:draft_permit) { create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'draft') }
    let!(:approved_permit) { 
      create(:immo_promo_permit, 
        project: project, 
        permit_type: 'construction', 
        status: 'approved', 
        expiry_date: 3.months.from_now
      ) 
    }

    it 'returns upcoming deadlines' do
      deadlines = controller.upcoming_permit_deadlines
      
      expect(deadlines.length).to eq(2)
      
      submission_deadline = deadlines.find { |d| d[:type] == 'submission' }
      expect(submission_deadline[:permit]).to eq(draft_permit)
      expect(submission_deadline[:urgency]).to be_present
      
      expiry_deadline = deadlines.find { |d| d[:type] == 'expiry' }
      expect(expiry_deadline[:permit]).to eq(approved_permit)
      expect(expiry_deadline[:deadline]).to eq(approved_permit.expiry_date)
    end
  end

  describe '#permit_milestones' do
    let!(:submitted_permit) { 
      create(:immo_promo_permit, 
        project: project,
        permit_type: 'construction',
        status: 'approved',
        submission_date: 2.months.ago,
        response_date: 1.month.ago
      ) 
    }
    let!(:condition) { 
      create(:immo_promo_permit_condition, 
        permit: submitted_permit,
        status: 'validated',
        validated_at: 2.weeks.ago,
        description: 'Étude technique'
      ) 
    }

    it 'returns permit milestones chronologically' do
      milestones = controller.permit_milestones
      
      expect(milestones.length).to eq(3)
      
      # Should be sorted by date (most recent first)
      expect(milestones.first[:type]).to eq('condition_validated')
      expect(milestones.first[:title]).to include('Condition validée')
      
      expect(milestones.second[:type]).to eq('response')
      expect(milestones.second[:status]).to eq('success')
      
      expect(milestones.last[:type]).to eq('submission')
      expect(milestones.last[:status]).to eq('completed')
    end
  end

  describe 'deadline urgency calculation' do
    it 'correctly calculates urgency levels' do
      # Critical: 7 days or less
      expect(controller.send(:calculate_deadline_urgency, 5.days.from_now)).to eq('critical')
      
      # High: 8-30 days
      expect(controller.send(:calculate_deadline_urgency, 15.days.from_now)).to eq('high')
      
      # Medium: 31-60 days
      expect(controller.send(:calculate_deadline_urgency, 45.days.from_now)).to eq('medium')
      
      # Low: more than 60 days
      expect(controller.send(:calculate_deadline_urgency, 90.days.from_now)).to eq('low')
    end
  end

  describe 'submission date calculation' do
    context 'for construction permit' do
      let(:construction_permit) { create(:immo_promo_permit, project: project, permit_type: 'construction') }
      
      context 'when urban planning is approved' do
        let!(:urban_permit) { 
          create(:immo_promo_permit, project: project, permit_type: 'urban_planning', status: 'approved') 
        }

        it 'suggests near-term submission' do
          date = controller.send(:calculate_optimal_submission_date, construction_permit)
          expect(date).to eq(Date.current + 1.week)
        end
      end

      context 'when urban planning is not approved' do
        it 'suggests later submission' do
          date = controller.send(:calculate_optimal_submission_date, construction_permit)
          expect(date).to eq(Date.current + 3.months)
        end
      end
    end

    context 'for other permit types' do
      it 'suggests standard timeline' do
        date = controller.send(:calculate_optimal_submission_date, permit)
        expect(date).to eq(Date.current + 2.weeks)
      end
    end
  end
end