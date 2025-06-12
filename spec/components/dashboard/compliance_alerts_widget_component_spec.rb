# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ComplianceAlertsWidgetComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:juridique_profile) { create(:user_profile, user: user, profile_type: 'juridique', is_active: true) }
  let(:component) { described_class.new(user: user, max_alerts: 5) }

  before do
    user.update(active_profile: juridique_profile)
  end

  describe '#initialize' do
    it 'initializes with user and max_alerts' do
      expect(component).to be_a(described_class)
    end

    context 'when user is not juridique' do
      let(:other_profile) { create(:user_profile, user: user, profile_type: 'commercial', is_active: true) }
      
      before { user.update(active_profile: other_profile) }
      
      it 'loads empty alerts array' do
        expect(component.send(:alerts)).to be_empty
      end
    end
  end

  describe '#expiring_documents_alerts' do
    it 'includes documents expiring within 30 days' do
      expiring_soon = create(:document, expiry_date: 15.days.from_now, status: 'active')
      expiring_later = create(:document, expiry_date: 60.days.from_now, status: 'active')
      expired = create(:document, expiry_date: 5.days.ago, status: 'active')
      
      alerts = component.send(:expiring_documents_alerts)
      
      expect(alerts.map { |a| a[:description] }).to include(expiring_soon.name)
      expect(alerts.map { |a| a[:description] }).to include(expired.name)
      expect(alerts.map { |a| a[:description] }).not_to include(expiring_later.name)
    end
    
    it 'excludes inactive documents' do
      expiring = create(:document, expiry_date: 15.days.from_now, status: 'archived')
      
      alerts = component.send(:expiring_documents_alerts)
      
      expect(alerts.map { |a| a[:description] }).not_to include(expiring.name)
    end
  end

  describe '#permit_compliance_alerts' do
    context 'when Immo::Promo::Permit is defined' do
      let(:permit_class) { Class.new(ApplicationRecord) }
      
      before do
        stub_const('Immo::Promo::Permit', permit_class)
        allow(permit_class).to receive(:where).and_return(permit_class)
        allow(permit_class).to receive(:map).and_return([])
      end
      
      it 'queries permits with approaching deadlines' do
        expect(permit_class).to receive(:where).with(status: ['pending', 'submitted'])
        component.send(:permit_compliance_alerts)
      end
    end
    
    context 'when Immo::Promo::Permit is not defined' do
      it 'returns empty array' do
        hide_const('Immo::Promo::Permit')
        expect(component.send(:permit_compliance_alerts)).to eq([])
      end
    end
  end

  describe '#contract_renewal_alerts' do
    it 'includes contracts with renewal dates within 60 days' do
      renewing_soon = create(:document, 
        document_type: 'contract',
        metadata: { renewal_date: 30.days.from_now.to_s }
      )
      renewing_later = create(:document,
        document_type: 'contract', 
        metadata: { renewal_date: 90.days.from_now.to_s }
      )
      
      alerts = component.send(:contract_renewal_alerts)
      
      expect(alerts.map { |a| a[:description] }).to include(renewing_soon.name)
      expect(alerts.map { |a| a[:description] }).not_to include(renewing_later.name)
    end
  end

  describe '#legal_validation_alerts' do
    it 'includes pending legal validations assigned to user' do
      assigned = create(:validation_request,
        validation_type: 'legal',
        status: 'pending',
        assigned_to: user
      )
      other_type = create(:validation_request,
        validation_type: 'financial',
        status: 'pending',
        assigned_to: user
      )
      other_user = create(:validation_request,
        validation_type: 'legal',
        status: 'pending',
        assigned_to: create(:user)
      )
      
      alerts = component.send(:legal_validation_alerts)
      
      expect(alerts.map { |a| a[:description] }).to include(assigned.validatable.name)
      expect(alerts.map { |a| a[:description] }).not_to include(other_type.validatable.name)
      expect(alerts.map { |a| a[:description] }).not_to include(other_user.validatable.name)
    end
  end

  describe 'priority methods' do
    describe '#expiry_priority' do
      it 'returns high for <= 7 days' do
        expect(component.send(:expiry_priority, 5.days.from_now)).to eq('high')
      end
      
      it 'returns medium for <= 30 days' do
        expect(component.send(:expiry_priority, 20.days.from_now)).to eq('medium')
      end
      
      it 'returns low for > 30 days' do
        expect(component.send(:expiry_priority, 45.days.from_now)).to eq('low')
      end
    end
    
    describe '#deadline_priority' do
      it 'returns high for <= 3 days' do
        expect(component.send(:deadline_priority, 2.days.from_now)).to eq('high')
      end
      
      it 'returns medium for <= 7 days' do
        expect(component.send(:deadline_priority, 5.days.from_now)).to eq('medium')
      end
      
      it 'returns low for > 7 days' do
        expect(component.send(:deadline_priority, 10.days.from_now)).to eq('low')
      end
    end
    
    describe '#renewal_priority' do
      it 'returns high for <= 30 days' do
        expect(component.send(:renewal_priority, 25.days.from_now)).to eq('high')
      end
      
      it 'returns medium for <= 60 days' do
        expect(component.send(:renewal_priority, 45.days.from_now)).to eq('medium')
      end
      
      it 'returns low for > 60 days' do
        expect(component.send(:renewal_priority, 90.days.from_now)).to eq('low')
      end
    end
  end

  describe '#alert_priority_score' do
    it 'returns correct scores' do
      expect(component.send(:alert_priority_score, 'high')).to eq(0)
      expect(component.send(:alert_priority_score, 'medium')).to eq(1)
      expect(component.send(:alert_priority_score, 'low')).to eq(2)
      expect(component.send(:alert_priority_score, 'unknown')).to eq(3)
    end
  end

  describe '#days_until_text' do
    it 'returns correct text for different date ranges' do
      expect(component.send(:days_until_text, Date.current)).to eq("Aujourd'hui")
      expect(component.send(:days_until_text, Date.tomorrow)).to eq("Demain")
      expect(component.send(:days_until_text, 5.days.from_now)).to eq("Dans 5 jours")
      expect(component.send(:days_until_text, 3.days.ago)).to eq("En retard de 3 jours")
    end
  end

  describe '#gdpr_compliance_deadlines' do
    it 'includes deadlines within 90 days' do
      travel_to Date.new(2025, 4, 1) do
        deadlines = component.send(:gdpr_compliance_deadlines)
        
        expect(deadlines).to be_an(Array)
        expect(deadlines.any? { |d| d[:type] == 'gdpr_audit' }).to be_truthy
        expect(deadlines.any? { |d| d[:type] == 'gdpr_register' }).to be_truthy
      end
    end
  end

  describe '#calculate_stats' do
    before do
      allow(component).to receive(:alerts).and_return([
        { priority: 'high', type: 'document_expiry' },
        { priority: 'high', type: 'legal_validation' },
        { priority: 'medium', type: 'document_expiry' },
        { priority: 'low', type: 'permit_deadline' }
      ])
      
      allow(component).to receive(:upcoming_deadlines).and_return([{}, {}])
    end
    
    it 'calculates correct stats' do
      stats = component.send(:calculate_stats)
      
      expect(stats[:critical_alerts]).to eq(2)
      expect(stats[:total_alerts]).to eq(4)
      expect(stats[:documents_expiring]).to eq(2)
      expect(stats[:pending_validations]).to eq(1)
      expect(stats[:upcoming_deadlines]).to eq(2)
    end
  end

  describe 'rendering' do
    it 'renders successfully with no alerts' do
      render_inline(component)
      
      expect(page).to have_text('Alertes de conformité')
      expect(page).to have_text('Aucune alerte active')
      expect(page).to have_text('Tous les documents sont conformes')
    end
    
    context 'with alerts' do
      before do
        create(:document, name: 'Contrat important', expiry_date: 5.days.from_now, status: 'active')
        create(:validation_request,
          validation_type: 'legal',
          status: 'pending',
          assigned_to: user,
          validatable: create(:document, name: 'Document juridique')
        )
      end
      
      it 'renders alerts' do
        render_inline(described_class.new(user: user))
        
        expect(page).to have_text('Document expire bientôt')
        expect(page).to have_text('Contrat important')
        expect(page).to have_text('Validation juridique requise')
        expect(page).to have_text('Document juridique')
      end
      
      it 'shows critical alerts count' do
        render_inline(described_class.new(user: user))
        
        expect(page).to have_css('.bg-red-100')
        expect(page).to have_text('critique')
      end
    end
    
    context 'with upcoming deadlines' do
      before do
        travel_to Date.new(2025, 5, 1)
      end
      
      it 'shows regulatory deadlines' do
        render_inline(component)
        
        expect(page).to have_text('Échéances réglementaires')
      end
    end
  end
end