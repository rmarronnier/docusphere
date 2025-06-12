# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ClientDocumentsWidgetComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:commercial_profile) { create(:user_profile, user: user, profile_type: 'commercial', is_active: true) }
  let(:component) { described_class.new(user: user, max_clients: 3) }

  before do
    user.update(active_profile: commercial_profile)
  end

  describe '#initialize' do
    it 'initializes with user and max_clients' do
      expect(component).to be_a(described_class)
    end

    context 'when user is not commercial' do
      let(:other_profile) { create(:user_profile, user: user, profile_type: 'juridique', is_active: true) }
      
      before { user.update(active_profile: other_profile) }
      
      it 'loads empty clients array' do
        expect(component.send(:clients)).to be_empty
      end
    end
  end

  describe '#load_user_clients' do
    context 'when Immo::Promo::Stakeholder is defined' do
      before do
        stub_const('Immo::Promo::Stakeholder', Class.new(ApplicationRecord))
        stub_const('Immo::Promo::ProjectStakeholder', Class.new(ApplicationRecord))
        
        allow(Immo::Promo::Stakeholder).to receive(:where).and_return(Immo::Promo::Stakeholder)
        allow(Immo::Promo::Stakeholder).to receive(:joins).and_return(Immo::Promo::Stakeholder)
        allow(Immo::Promo::Stakeholder).to receive(:distinct).and_return(Immo::Promo::Stakeholder)
        allow(Immo::Promo::Stakeholder).to receive(:order).and_return(Immo::Promo::Stakeholder)
        allow(Immo::Promo::Stakeholder).to receive(:limit).and_return([])
      end
      
      it 'queries clients associated with user' do
        expect(Immo::Promo::Stakeholder).to receive(:where).with(stakeholder_type: 'client')
        component.send(:load_user_clients)
      end
    end
    
    context 'when Immo::Promo::Stakeholder is not defined' do
      it 'returns empty array' do
        hide_const('Immo::Promo::Stakeholder')
        expect(component.send(:load_user_clients)).to eq([])
      end
    end
  end

  describe '#count_proposals' do
    let(:client) { double('client', id: 1) }
    
    it 'counts proposal documents for client' do
      create(:document, document_type: 'proposal', metadata: { client_id: '1' })
      create(:document, document_type: 'proposal', metadata: { client_id: '1' })
      create(:document, document_type: 'contract', metadata: { client_id: '1' })
      
      expect(component.send(:count_proposals, client)).to eq(2)
    end
  end

  describe '#count_contracts' do
    let(:client) { double('client', id: 1) }
    
    it 'counts contract documents for client' do
      create(:document, document_type: 'contract', metadata: { client_id: '1' })
      create(:document, document_type: 'contract', metadata: { client_id: '1' })
      create(:document, document_type: 'proposal', metadata: { client_id: '1' })
      
      expect(component.send(:count_contracts, client)).to eq(2)
    end
  end

  describe '#client_status_badge' do
    let(:client) { double('client', id: 1) }
    
    before do
      allow(component).to receive(:documents_by_client).and_return({
        1 => client_data
      })
    end
    
    context 'with contracts' do
      let(:client_data) { { contracts_count: 2, proposals_count: 0, shared_count: 0 } }
      
      it 'returns client actif status' do
        status = component.send(:client_status_badge, client)
        expect(status[:label]).to eq('Client actif')
        expect(status[:color]).to include('green')
      end
    end
    
    context 'with proposals' do
      let(:client_data) { { contracts_count: 0, proposals_count: 1, shared_count: 0 } }
      
      it 'returns proposition en cours status' do
        status = component.send(:client_status_badge, client)
        expect(status[:label]).to eq('Proposition en cours')
        expect(status[:color]).to include('blue')
      end
    end
    
    context 'with shared documents only' do
      let(:client_data) { { contracts_count: 0, proposals_count: 0, shared_count: 3 } }
      
      it 'returns prospect qualifié status' do
        status = component.send(:client_status_badge, client)
        expect(status[:label]).to eq('Prospect qualifié')
        expect(status[:color]).to include('yellow')
      end
    end
    
    context 'with no documents' do
      let(:client_data) { { contracts_count: 0, proposals_count: 0, shared_count: 0 } }
      
      it 'returns nouveau prospect status' do
        status = component.send(:client_status_badge, client)
        expect(status[:label]).to eq('Nouveau prospect')
        expect(status[:color]).to include('gray')
      end
    end
  end

  describe '#document_action_for_type' do
    it 'returns correct action for document types' do
      proposal = double('document', document_type: 'proposal')
      contract = double('document', document_type: 'contract')
      brochure = double('document', document_type: 'brochure')
      other = double('document', document_type: 'other')
      
      expect(component.send(:document_action_for_type, proposal)[:label]).to eq('Envoyer')
      expect(component.send(:document_action_for_type, contract)[:label]).to eq('Faire signer')
      expect(component.send(:document_action_for_type, brochure)[:label]).to eq('Partager')
      expect(component.send(:document_action_for_type, other)[:label]).to eq('Consulter')
    end
  end

  describe '#client_contact_info' do
    it 'combines email and phone' do
      client = double('client', email: 'test@example.com', phone: '0123456789')
      expect(component.send(:client_contact_info, client)).to eq('test@example.com • 0123456789')
    end
    
    it 'shows only email when no phone' do
      client = double('client', email: 'test@example.com', phone: nil)
      expect(component.send(:client_contact_info, client)).to eq('test@example.com')
    end
    
    it 'shows only phone when no email' do
      client = double('client', email: '', phone: '0123456789')
      expect(component.send(:client_contact_info, client)).to eq('0123456789')
    end
  end

  describe '#last_interaction_time' do
    let(:client) { double('client', id: 1) }
    
    it 'shows last document activity' do
      doc = create(:document, created_at: 3.days.ago)
      allow(component).to receive(:documents_by_client).and_return({
        1 => { recent: [doc] }
      })
      
      expect(component.send(:last_interaction_time, client)).to include('Dernière activité')
    end
    
    it 'shows no interaction when no documents' do
      allow(component).to receive(:documents_by_client).and_return({
        1 => { recent: [] }
      })
      
      expect(component.send(:last_interaction_time, client)).to eq('Aucune interaction')
    end
  end

  describe 'rendering' do
    it 'renders successfully with no clients' do
      render_inline(component)
      
      expect(page).to have_text('Documents clients')
      expect(page).to have_text('Aucun client')
      expect(page).to have_text("Vous n'avez pas encore de clients assignés")
    end
    
    context 'with mock clients' do
      let(:client1) do
        double('client',
          id: 1,
          name: 'ACME Corp',
          email: 'contact@acme.com',
          phone: '0123456789'
        )
      end
      
      let(:client2) do
        double('client',
          id: 2,
          name: 'Beta Inc',
          email: 'info@beta.com',
          phone: nil
        )
      end
      
      before do
        allow(component).to receive(:clients).and_return([client1, client2])
        allow(component).to receive(:documents_by_client).and_return({
          1 => {
            recent: create_list(:document, 2, document_type: 'proposal'),
            total_count: 10,
            proposals_count: 2,
            contracts_count: 1,
            shared_count: 7
          },
          2 => {
            recent: [],
            total_count: 0,
            proposals_count: 0,
            contracts_count: 0,
            shared_count: 0
          }
        })
        
        allow(component).to receive(:stats).and_return({
          total_clients: 2,
          total_documents: 10,
          active_proposals: 2,
          signed_contracts: 1,
          recent_shares: 3
        })
      end
      
      it 'renders client information' do
        render_inline(component)
        
        expect(page).to have_text('ACME Corp')
        expect(page).to have_text('Beta Inc')
        expect(page).to have_text('contact@acme.com • 0123456789')
        expect(page).to have_text('info@beta.com')
      end
      
      it 'shows client stats' do
        render_inline(component)
        
        expect(page).to have_text('2 Clients actifs')
        expect(page).to have_text('2 Propositions')
        expect(page).to have_text('1 Contrats signés')
        expect(page).to have_text('3 Partages récents')
      end
      
      it 'shows client status badges' do
        render_inline(component)
        
        expect(page).to have_text('Client actif') # client1 has contracts
        expect(page).to have_text('Nouveau prospect') # client2 has no documents
      end
      
      it 'shows document counts for clients' do
        render_inline(component)
        
        expect(page).to have_text('10 documents')
        expect(page).to have_text('2 propositions')
        expect(page).to have_text('1 contrat')
      end
      
      it 'shows empty state for client without documents' do
        render_inline(component)
        
        expect(page).to have_text('Aucun document partagé')
      end
    end
  end
end