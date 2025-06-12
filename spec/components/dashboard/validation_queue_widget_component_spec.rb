# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ValidationQueueWidgetComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:direction_profile) { create(:user_profile, user: user, profile_type: 'direction', is_active: true) }
  let(:component) { described_class.new(user: user, max_items: 5) }

  before do
    user.update(active_profile: direction_profile)
  end

  describe '#initialize' do
    it 'initializes with user and max_items' do
      expect(component).to be_a(described_class)
    end

    it 'loads validation requests' do
      create_list(:validation_request, 3, assigned_to: user, status: 'pending')
      component = described_class.new(user: user)
      expect(component.send(:validation_requests).count).to eq(3)
    end

    it 'respects max_items limit' do
      create_list(:validation_request, 10, assigned_to: user, status: 'pending')
      expect(component.send(:validation_requests).count).to eq(5)
    end

    it 'calculates stats correctly' do
      create(:validation_request, assigned_to: user, status: 'pending', priority: 'high')
      create(:validation_request, assigned_to: user, status: 'pending', priority: 'medium')
      create(:validation_request, assigned_to: user, status: 'pending', priority: 'low')
      
      component = described_class.new(user: user)
      stats = component.send(:stats)
      
      expect(stats[:total_pending]).to eq(3)
      expect(stats[:high_priority]).to eq(1)
    end
  end

  describe '#load_validation_requests' do
    context 'for direction profile' do
      it 'loads assigned requests and high priority requests' do
        assigned = create(:validation_request, assigned_to: user, status: 'pending', priority: 'medium')
        high_priority = create(:validation_request, assigned_to: create(:user), status: 'pending', priority: 'high')
        other = create(:validation_request, assigned_to: create(:user), status: 'pending', priority: 'low')
        
        requests = component.send(:load_validation_requests)
        
        expect(requests).to include(assigned)
        expect(requests).to include(high_priority)
        expect(requests).not_to include(other)
      end
    end

    context 'for non-direction profile' do
      let(:user_profile) { create(:user_profile, user: user, profile_type: 'commercial', is_active: true) }
      
      before { user.update(active_profile: user_profile) }
      
      it 'loads only assigned requests' do
        assigned = create(:validation_request, assigned_to: user, status: 'pending')
        other = create(:validation_request, assigned_to: create(:user), status: 'pending', priority: 'high')
        
        requests = component.send(:load_validation_requests)
        
        expect(requests).to include(assigned)
        expect(requests).not_to include(other)
      end
    end

    it 'orders by priority and created_at' do
      old_high = create(:validation_request, assigned_to: user, status: 'pending', priority: 'high', created_at: 2.days.ago)
      new_high = create(:validation_request, assigned_to: user, status: 'pending', priority: 'high', created_at: 1.day.ago)
      medium = create(:validation_request, assigned_to: user, status: 'pending', priority: 'medium', created_at: 1.hour.ago)
      
      requests = component.send(:load_validation_requests).to_a
      
      expect(requests[0]).to eq(old_high)
      expect(requests[1]).to eq(new_high)
      expect(requests[2]).to eq(medium)
    end
  end

  describe '#calculate_average_age' do
    it 'calculates average age in days' do
      create(:validation_request, assigned_to: user, status: 'pending', created_at: 5.days.ago)
      create(:validation_request, assigned_to: user, status: 'pending', created_at: 3.days.ago)
      
      component = described_class.new(user: user)
      
      expect(component.send(:calculate_average_age)).to eq(4.0)
    end

    it 'returns 0 when no requests' do
      expect(component.send(:calculate_average_age)).to eq(0)
    end
  end

  describe '#priority_color' do
    it 'returns correct colors for priorities' do
      expect(component.send(:priority_color, 'high')).to eq('text-red-600 bg-red-100')
      expect(component.send(:priority_color, 'medium')).to eq('text-yellow-600 bg-yellow-100')
      expect(component.send(:priority_color, 'low')).to eq('text-green-600 bg-green-100')
      expect(component.send(:priority_color, 'unknown')).to eq('text-gray-600 bg-gray-100')
    end
  end

  describe '#document_icon' do
    it 'returns file icon when validatable has no file_content_type' do
      validatable = double('validatable')
      expect(component.send(:document_icon, validatable)).to eq('file')
    end

    it 'returns specific icon based on content type' do
      pdf_doc = create(:document, :with_pdf_file)
      expect(component.send(:document_icon, pdf_doc)).to eq('file-pdf')
    end
  end

  describe '#validation_type_label' do
    it 'returns French labels for known types' do
      expect(component.send(:validation_type_label, 'content')).to eq('Contenu')
      expect(component.send(:validation_type_label, 'compliance')).to eq('Conformité')
      expect(component.send(:validation_type_label, 'financial')).to eq('Financier')
      expect(component.send(:validation_type_label, 'legal')).to eq('Juridique')
      expect(component.send(:validation_type_label, 'technical')).to eq('Technique')
    end

    it 'humanizes unknown types' do
      expect(component.send(:validation_type_label, 'custom_type')).to eq('Custom type')
    end
  end

  describe '#time_ago_with_urgency' do
    it 'shows urgency for old requests' do
      old_date = 10.days.ago
      result = component.send(:time_ago_with_urgency, old_date)
      
      expect(result).to include('text-red-600')
      expect(result).to include('font-semibold')
      expect(result).to include('10 jours')
    end

    it 'shows warning for medium age requests' do
      medium_date = 5.days.ago
      result = component.send(:time_ago_with_urgency, medium_date)
      
      expect(result).to include('text-yellow-600')
      expect(result).to include('5 jours')
    end

    it 'shows normal text for recent requests' do
      recent_date = 2.days.ago
      result = component.send(:time_ago_with_urgency, recent_date)
      
      expect(result).to eq('il y a 2 jours')
    end
  end

  describe '#bulk_validation_enabled?' do
    it 'returns true for direction with multiple pending' do
      create_list(:validation_request, 2, assigned_to: user, status: 'pending')
      component = described_class.new(user: user)
      
      expect(component.send(:bulk_validation_enabled?)).to be_truthy
    end

    it 'returns false for non-direction profile' do
      user.active_profile.update(profile_type: 'commercial')
      create_list(:validation_request, 2, assigned_to: user, status: 'pending')
      component = described_class.new(user: user)
      
      expect(component.send(:bulk_validation_enabled?)).to be_falsey
    end

    it 'returns false with single pending request' do
      create(:validation_request, assigned_to: user, status: 'pending')
      component = described_class.new(user: user)
      
      expect(component.send(:bulk_validation_enabled?)).to be_falsey
    end
  end

  describe 'rendering' do
    it 'renders successfully with no requests' do
      render_inline(component)
      
      expect(page).to have_text('File de validation')
      expect(page).to have_text('Aucune validation en attente')
    end

    it 'renders validation requests' do
      document = create(:document, name: 'Document important')
      request = create(:validation_request, 
        validatable: document,
        assigned_to: user, 
        status: 'pending',
        priority: 'high',
        validation_type: 'legal',
        message: 'Validation urgente requise'
      )
      
      render_inline(component)
      
      expect(page).to have_text('Document important')
      expect(page).to have_text('HIGH')
      expect(page).to have_text('Juridique')
      expect(page).to have_text('Validation urgente requise')
    end

    it 'shows stats correctly' do
      create(:validation_request, assigned_to: user, status: 'pending', priority: 'high')
      create(:validation_request, assigned_to: user, status: 'pending', priority: 'medium')
      
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('2') # Total pending
      expect(page).to have_text('1') # High priority
    end

    it 'shows bulk validation button for direction' do
      create_list(:validation_request, 2, assigned_to: user, status: 'pending')
      
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Validation groupée')
    end

    it 'shows footer with link' do
      create(:validation_request, assigned_to: user, status: 'pending')
      
      render_inline(component)
      
      expect(page).to have_text('Voir toutes les validations')
      expect(page).to have_text('Affichage de 1 validation')
    end
  end
end