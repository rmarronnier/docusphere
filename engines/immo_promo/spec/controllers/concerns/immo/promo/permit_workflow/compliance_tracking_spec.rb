require 'rails_helper'

RSpec.describe Immo::Promo::PermitWorkflow::ComplianceTracking, type: :concern do

  let(:controller_class) do
    Class.new(ApplicationController) do
      include Immo::Promo::PermitWorkflow::ComplianceTracking
      
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
      
      def immo_promo_engine
        double('engine', project_permit_workflow_compliance_checklist_path: '/compliance')
      end
    end
  end
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_type: 'residential') }
  let(:permit) { create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'approved') }
  let(:condition) { create(:immo_promo_permit_condition, permit: permit, condition_type: 'technical_study') }
  let(:controller) { controller_class.new(project, user) }

  describe '#validate_condition' do
    before do
      controller.params = { 
        permit_id: permit.id, 
        condition_id: condition.id,
        validation_data: 'Complete data',
        validation_notes: 'Technical study approved'
      }
    end

    context 'when validation is successful' do
      it 'validates the condition' do
        controller.validate_condition
        
        condition.reload
        expect(condition.status).to eq('validated')
        expect(condition.validated_at).to eq(Date.current)
        expect(condition.validated_by).to eq(user)
        expect(condition.validation_notes).to eq('Technical study approved')
        expect(controller.flash[:success]).to eq('Condition validée avec succès')
      end
    end

    context 'when validation fails' do
      before do
        controller.params[:validation_data] = nil
      end

      it 'shows validation error' do
        controller.validate_condition
        
        condition.reload
        expect(condition.status).not_to eq('validated')
        expect(controller.flash[:error]).to include('Condition non validée')
      end
    end
  end

  describe '#get_regulatory_requirements_for_project' do
    context 'for residential project' do
      it 'returns residential-specific requirements' do
        requirements = controller.get_regulatory_requirements_for_project
        
        expect(requirements.length).to eq(3)
        categories = requirements.map { |r| r[:category] }
        expect(categories).to include('Urbanisme', 'Accessibilité', 'Thermique')
        
        urbanisme_req = requirements.find { |r| r[:category] == 'Urbanisme' }
        expect(urbanisme_req[:requirements]).to include('Respect du PLU/POS')
      end
    end

    context 'for commercial project' do
      let(:project) { create(:immo_promo_project, organization: organization, project_type: 'commercial') }

      it 'returns commercial-specific requirements' do
        requirements = controller.get_regulatory_requirements_for_project
        
        categories = requirements.map { |r| r[:category] }
        expect(categories).to include('Urbanisme Commercial', 'Sécurité Incendie')
        
        commercial_req = requirements.find { |r| r[:category] == 'Urbanisme Commercial' }
        expect(commercial_req[:requirements]).to include('Autorisation CDAC si > 1000m²')
      end
    end

    context 'for industrial project' do
      let(:project) { create(:immo_promo_project, organization: organization, project_type: 'industrial') }

      it 'returns industrial-specific requirements' do
        requirements = controller.get_regulatory_requirements_for_project
        
        categories = requirements.map { |r| r[:category] }
        expect(categories).to include('Environnement', 'Sécurité Industrielle')
        
        env_req = requirements.find { |r| r[:category] == 'Environnement' }
        expect(env_req[:requirements]).to include('Autorisation ICPE')
      end
    end

    context 'for unknown project type' do
      let(:project) { create(:immo_promo_project, organization: organization, project_type: 'unknown') }

      it 'returns basic requirements' do
        requirements = controller.get_regulatory_requirements_for_project
        
        expect(requirements.length).to eq(1)
        expect(requirements.first[:category]).to eq('Base')
        expect(requirements.first[:requirements]).to include('Permis de construire')
      end
    end
  end

  describe '#identify_missing_documents' do
    context 'for residential project' do
      before do
        # Create some existing documents
        create(:document, 
          documentable: project, 
          document_type: 'plans_masse',
          organization: organization
        )
        create(:document, 
          documentable: project, 
          document_type: 'plans_facades',
          organization: organization
        )
      end

      it 'identifies missing required documents' do
        missing = controller.identify_missing_documents
        
        expect(missing).to include('etude_thermique', 'notice_accessibilite')
        expect(missing).not_to include('plans_masse', 'plans_facades')
      end
    end

    context 'for commercial project' do
      let(:project) { create(:immo_promo_project, organization: organization, project_type: 'commercial') }

      it 'identifies commercial-specific missing documents' do
        missing = controller.identify_missing_documents
        
        expect(missing).to include('etude_impact_commercial', 'notice_securite_incendie')
      end
    end
  end

  describe '#check_permit_conditions_compliance' do
    let!(:condition1) { 
      create(:immo_promo_permit_condition, 
        permit: permit, 
        condition_type: 'technical_study',
        status: 'validated'
      ) 
    }
    let!(:condition2) { 
      create(:immo_promo_permit_condition, 
        permit: permit, 
        condition_type: 'environmental_measure',
        status: 'pending'
      ) 
    }

    it 'returns comprehensive compliance data' do
      compliance = controller.check_permit_conditions_compliance
      
      expect(compliance).to have_key(permit.id)
      
      permit_compliance = compliance[permit.id]
      expect(permit_compliance[:permit]).to eq(permit)
      expect(permit_compliance[:conditions].length).to eq(2)
      
      validated_condition = permit_compliance[:conditions].find { |c| c[:condition] == condition1 }
      expect(validated_condition[:compliance_level]).to eq('compliant')
      expect(validated_condition[:required_actions]).to be_empty
      
      pending_condition = permit_compliance[:conditions].find { |c| c[:condition] == condition2 }
      expect(pending_condition[:compliance_level]).to eq('non_compliant')
      expect(pending_condition[:required_actions]).not_to be_empty
    end
  end

  describe '#assess_condition_compliance' do
    it 'correctly assesses compliance levels' do
      validated_condition = create(:immo_promo_permit_condition, status: 'validated')
      expect(controller.send(:assess_condition_compliance, validated_condition)).to eq('compliant')
      
      in_progress_condition = create(:immo_promo_permit_condition, status: 'in_progress')
      expect(controller.send(:assess_condition_compliance, in_progress_condition)).to eq('partially_compliant')
      
      pending_condition = create(:immo_promo_permit_condition, status: 'pending')
      expect(controller.send(:assess_condition_compliance, pending_condition)).to eq('non_compliant')
      
      unknown_condition = create(:immo_promo_permit_condition, status: 'unknown_status')
      expect(controller.send(:assess_condition_compliance, unknown_condition)).to eq('unknown')
    end
  end

  describe '#get_condition_required_actions' do
    context 'for validated condition' do
      let(:validated_condition) { create(:immo_promo_permit_condition, status: 'validated') }

      it 'returns no required actions' do
        actions = controller.send(:get_condition_required_actions, validated_condition)
        expect(actions).to be_empty
      end
    end

    context 'for technical study condition' do
      let(:technical_condition) { 
        create(:immo_promo_permit_condition, 
          condition_type: 'technical_study',
          status: 'pending'
        ) 
      }

      it 'returns technical study specific actions' do
        actions = controller.send(:get_condition_required_actions, technical_condition)
        
        expect(actions).to include('Réaliser l\'étude technique')
        expect(actions).to include('Faire valider par bureau de contrôle')
      end
    end

    context 'for environmental measure condition' do
      let(:env_condition) { 
        create(:immo_promo_permit_condition, 
          condition_type: 'environmental_measure',
          status: 'pending'
        ) 
      }

      it 'returns environmental specific actions' do
        actions = controller.send(:get_condition_required_actions, env_condition)
        
        expect(actions).to include('Mettre en place les mesures compensatoires')
        expect(actions).to include('Obtenir validation environnementale')
      end
    end

    context 'for accessibility compliance condition' do
      let(:accessibility_condition) { 
        create(:immo_promo_permit_condition, 
          condition_type: 'accessibility_compliance',
          status: 'pending'
        ) 
      }

      it 'returns accessibility specific actions' do
        actions = controller.send(:get_condition_required_actions, accessibility_condition)
        
        expect(actions).to include('Adapter les plans pour conformité PMR')
        expect(actions).to include('Valider avec commission accessibilité')
      end
    end

    context 'for unknown condition type' do
      let(:unknown_condition) { 
        create(:immo_promo_permit_condition, 
          condition_type: 'unknown_type',
          status: 'pending'
        ) 
      }

      it 'returns generic actions' do
        actions = controller.send(:get_condition_required_actions, unknown_condition)
        
        expect(actions).to include('Vérifier les exigences spécifiques')
        expect(actions).to include('Soumettre les justificatifs')
      end
    end
  end

  describe '#validate_permit_condition' do
    context 'with valid data' do
      it 'validates successfully' do
        result = controller.send(:validate_permit_condition, condition, 'Valid data')
        
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context 'with missing data' do
      it 'fails validation' do
        result = controller.send(:validate_permit_condition, condition, nil)
        
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Données de validation manquantes')
      end
    end
  end

  describe 'required documents by project type' do
    describe '#get_required_documents_for_project' do
      context 'for residential project' do
        it 'returns residential document requirements' do
          required = controller.send(:get_required_documents_for_project)
          
          expect(required).to eq(%w[plans_masse plans_facades etude_thermique notice_accessibilite])
        end
      end

      context 'for commercial project' do
        let(:project) { create(:immo_promo_project, organization: organization, project_type: 'commercial') }

        it 'returns commercial document requirements' do
          required = controller.send(:get_required_documents_for_project)
          
          expect(required).to eq(%w[plans_masse plans_facades etude_impact_commercial notice_securite_incendie])
        end
      end

      context 'for industrial project' do
        let(:project) { create(:immo_promo_project, organization: organization, project_type: 'industrial') }

        it 'returns industrial document requirements' do
          required = controller.send(:get_required_documents_for_project)
          
          expect(required).to eq(%w[plans_masse plans_facades etude_impact_environnemental dossier_icpe])
        end
      end

      context 'for basic project' do
        let(:project) { create(:immo_promo_project, organization: organization, project_type: 'basic') }

        it 'returns basic document requirements' do
          required = controller.send(:get_required_documents_for_project)
          
          expect(required).to eq(%w[plans_masse plans_facades])
        end
      end
    end
  end
end