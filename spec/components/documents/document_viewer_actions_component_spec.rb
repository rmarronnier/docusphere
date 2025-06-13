# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Documents::DocumentViewerActionsComponent, type: :component do
  let(:user) { create(:user) }
  let(:document) do
    double("Document",
      id: 1,
      title: "Test Document",
      pending_validation?: false,
      can_request_validation?: false,
      requires_legal_review?: false,
      contract?: false,
      plan?: false,
      technical_drawing?: false,
      pricing_document?: false,
      requires_validation?: false,
      technical_document?: false
    )
  end
  let(:profile_type) { 'direction' } # Default profile type
  let(:user_profile) { create(:user_profile, user: user, profile_type: profile_type) }
  let(:component) { described_class.new(document: document, user_profile: user_profile) }
  
  before do
    # Mock helpers with all required routes
    mock_helpers = double("helpers")
    allow(mock_helpers).to receive(:ged_approve_document_path).and_return("/ged/documents/#{document.id}/approve")
    allow(mock_helpers).to receive(:ged_reject_document_path).and_return("/ged/documents/#{document.id}/reject")
    allow(mock_helpers).to receive(:ged_request_validation_document_path).and_return("/ged/documents/#{document.id}/request_validation")
    allow(mock_helpers).to receive(:ged_validate_compliance_document_path).and_return("/ged/documents/#{document.id}/validate_compliance")
    allow(mock_helpers).to receive(:ged_edit_document_path).and_return("/ged/documents/#{document.id}/edit")
    allow(mock_helpers).to receive(:ged_legal_archive_document_path).and_return("/ged/documents/#{document.id}/legal_archive")
    allow(mock_helpers).to receive(:ged_technical_review_document_path).and_return("/ged/documents/#{document.id}/technical_review")
    allow(mock_helpers).to receive(:new_proposal_from_document_path).and_return("/proposals/new?document_id=#{document.id}")
    allow(mock_helpers).to receive(:ged_validate_document_path).and_return("/ged/documents/#{document.id}/validate")
    allow(mock_helpers).to receive(:ged_check_compliance_document_path).and_return("/ged/documents/#{document.id}/check_compliance")
    allow(mock_helpers).to receive(:add_to_audit_trail_document_path).and_return("/ged/documents/#{document.id}/add_to_audit_trail")
    allow(mock_helpers).to receive(:ged_technical_validation_document_path).and_return("/ged/documents/#{document.id}/technical_validation")
    allow(mock_helpers).to receive(:ged_verify_specs_document_path).and_return("/ged/documents/#{document.id}/verify_specs")
    allow(mock_helpers).to receive(:current_user).and_return(user)
    allow_any_instance_of(described_class).to receive(:helpers).and_return(mock_helpers)
  end
  
  describe '#initialize' do
    it 'accepts document and user_profile' do
      expect(component).to be_a(described_class)
    end
    
    it 'accepts optional context' do
      component = described_class.new(document: document, user_profile: user_profile, context: :validation)
      expect(component).to be_a(described_class)
    end
  end
  
  describe 'profile-specific actions' do
    context 'direction profile' do
      let(:profile_type) { 'direction' }
      
      it 'shows approval actions for pending documents' do
        allow(document).to receive(:pending_validation?).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Approuver')
        expect(page).to have_text('Rejeter')
      end
      
      it 'shows assignment and priority actions' do
        render_inline(component)
        
        expect(page).to have_text('Assigner')
        expect(page).to have_text('Définir priorité')
      end
    end
    
    context 'chef_projet profile' do
      let(:profile_type) { 'chef_projet' }
      
      it 'shows project management actions' do
        render_inline(component)
        
        expect(page).to have_text('Lier au projet')
        expect(page).to have_text('Assigner à phase')
        expect(page).to have_text('Distribuer équipe')
      end
      
      it 'shows validation request for eligible documents' do
        allow(document).to receive(:can_request_validation?).with(user).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Demander validation')
      end
    end
    
    context 'juriste profile' do
      let(:profile_type) { 'juriste' }
      
      it 'shows legal actions' do
        render_inline(component)
        
        expect(page).to have_text('Notes juridiques')
        expect(page).to have_text('Archiver légalement')
      end
      
      it 'shows compliance validation for documents requiring review' do
        allow(document).to receive(:requires_legal_review?).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Valider conformité')
      end
      
      it 'shows contract revision for contract documents' do
        allow(document).to receive(:contract?).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Réviser contrat')
      end
    end
    
    context 'architecte profile' do
      let(:profile_type) { 'architecte' }
      
      it 'shows architect actions' do
        render_inline(component)
        
        expect(page).to have_text('Demander modification')
      end
      
      it 'shows technical actions for plans' do
        allow(document).to receive(:plan?).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Révision technique')
        expect(page).to have_text('Annoter plan')
      end
    end
    
    context 'commercial profile' do
      let(:profile_type) { 'commercial' }
      
      it 'shows commercial actions' do
        render_inline(component)
        
        expect(page).to have_text('Partager avec client')
        expect(page).to have_text('Mettre à jour prix')
      end
      
      it 'shows proposal creation for pricing documents' do
        allow(document).to receive(:pricing_document?).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Créer proposition')
      end
    end
    
    context 'controle_gestion profile' do
      let(:profile_type) { 'controleur' }
      
      it 'shows controller actions' do
        render_inline(component)
        
        expect(page).to have_text('Vérifier conformité')
        expect(page).to have_text('Ajouter à piste audit')
      end
      
      it 'shows validation for documents requiring it' do
        # First ensure action gets rendered
        allow(document).to receive(:requires_validation?).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Valider')
      end
    end
    
    context 'expert_technique profile' do
      let(:profile_type) { 'expert_technique' }
      
      it 'shows technical expert actions' do
        render_inline(component)
        
        expect(page).to have_text('Ajouter notes techniques')
        expect(page).to have_text('Vérifier spécifications')
      end
      
      it 'shows technical validation for technical documents' do
        allow(document).to receive(:technical_document?).and_return(true)
        render_inline(component)
        
        expect(page).to have_text('Valider techniquement')
      end
    end
    
    context 'unknown profile' do
      let(:user_profile) { create(:user_profile, user: user, profile_type: 'expert_technique') }
      let(:component) { described_class.new(document: document, user_profile: user_profile) }
      
      it 'shows no actions' do
        # Override profile_type for this specific test
        allow(user_profile).to receive(:profile_type).and_return('unknown')
        render_inline(component)
        
        expect(page).not_to have_css('.document-viewer-actions div')
      end
    end
    
    context 'no profile' do
      let(:user_profile) { nil }
      
      it 'shows no actions' do
        render_inline(component)
        
        expect(page).not_to have_css('.document-viewer-actions div')
      end
    end
  end
  
  describe 'action buttons' do
    it 'renders buttons with correct classes' do
      allow(document).to receive(:pending_validation?).and_return(true)
      render_inline(component)
      
      expect(page).to have_css('a.btn-success', text: 'Approuver')
      expect(page).to have_css('a.btn-danger', text: 'Rejeter')
    end
    
    it 'includes icons in buttons' do
      render_inline(component)
      
      expect(page).to have_css('a svg') # Icon component renders SVG
    end
    
    it 'includes data attributes for modals' do
      render_inline(component)
      
      expect(page).to have_css('a[data-action="click->modal#open"]')
      expect(page).to have_css('a[data-modal-target="assign-modal"]')
    end
    
    it 'includes confirmation for dangerous actions' do
      allow(document).to receive(:pending_validation?).and_return(true)
      render_inline(component)
      
      reject_button = page.find('a', text: 'Rejeter')
      expect(reject_button['data-confirm']).to eq('Êtes-vous sûr de vouloir rejeter ce document ?')
    end
  end
end