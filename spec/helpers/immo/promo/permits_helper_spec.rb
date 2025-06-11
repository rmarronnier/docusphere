require 'rails_helper'

RSpec.describe Immo::Promo::PermitsHelper, type: :helper do
  let(:project) { create(:immo_promo_project) }
  let(:permit) { create(:immo_promo_permit, project: project) }
  
  describe '#permit_status_icon' do
    it 'returns appropriate icon for permit status' do
      expect(helper.permit_status_icon('approved')).to have_css('.icon-check-circle.text-success')
      expect(helper.permit_status_icon('rejected')).to have_css('.icon-x-circle.text-danger')
      expect(helper.permit_status_icon('pending')).to have_css('.icon-clock.text-warning')
      expect(helper.permit_status_icon('submitted')).to have_css('.icon-send.text-info')
    end
  end
  
  describe '#permit_timeline' do
    before do
      permit.submitted_at = 10.days.ago
      permit.approved_at = 2.days.ago
    end
    
    it 'displays permit processing timeline' do
      result = helper.permit_timeline(permit)
      
      expect(result).to have_css('.timeline')
      expect(result).to have_content('Submitted')
      expect(result).to have_content('Approved')
      expect(result).to have_content('8 days processing time')
    end
  end
  
  describe '#permit_expiry_badge' do
    it 'shows urgent badge for soon expiring permits' do
      permit.expiry_date = 5.days.from_now
      result = helper.permit_expiry_badge(permit)
      
      expect(result).to have_css('.badge.badge-danger')
      expect(result).to have_content('Expires in 5 days')
    end
    
    it 'shows warning badge for permits expiring within month' do
      permit.expiry_date = 20.days.from_now
      result = helper.permit_expiry_badge(permit)
      
      expect(result).to have_css('.badge.badge-warning')
    end
    
    it 'shows expired badge for past expiry' do
      permit.expiry_date = 1.day.ago
      result = helper.permit_expiry_badge(permit)
      
      expect(result).to have_css('.badge.badge-dark')
      expect(result).to have_content('Expired')
    end
  end
  
  describe '#permit_conditions_list' do
    before do
      create(:immo_promo_permit_condition, 
        permit: permit, 
        description: 'Noise restrictions',
        deadline: 1.week.from_now,
        is_fulfilled: false
      )
      create(:immo_promo_permit_condition,
        permit: permit,
        description: 'Safety measures',
        is_fulfilled: true
      )
    end
    
    it 'displays conditions with fulfillment status' do
      result = helper.permit_conditions_list(permit)
      
      expect(result).to have_css('.condition-item', count: 2)
      expect(result).to have_css('.fulfilled')
      expect(result).to have_css('.pending')
      expect(result).to have_content('Due in 7 days')
    end
  end
  
  describe '#permit_type_label' do
    it 'formats permit type with icon' do
      permit.permit_type = 'building'
      result = helper.permit_type_label(permit)
      
      expect(result).to have_css('.permit-type')
      expect(result).to have_css('.icon-building')
      expect(result).to have_content('Building Permit')
    end
  end
  
  describe '#permit_authority_info' do
    it 'displays issuing authority details' do
      permit.issuing_authority = 'City Planning Department'
      permit.metadata['authority_contact'] = {
        'phone' => '555-0123',
        'email' => 'permits@city.gov'
      }
      
      result = helper.permit_authority_info(permit)
      
      expect(result).to have_content('City Planning Department')
      expect(result).to have_link('555-0123')
      expect(result).to have_link('permits@city.gov')
    end
  end
  
  describe '#permit_dependency_tree' do
    it 'shows permit dependencies' do
      dependent_permit = create(:immo_promo_permit, 
        project: project,
        permit_type: 'occupancy',
        metadata: { 'depends_on' => [permit.id] }
      )
      
      result = helper.permit_dependency_tree(project)
      
      expect(result).to have_css('.dependency-tree')
      expect(result).to have_content(permit.reference_number)
      expect(result).to have_content(dependent_permit.reference_number)
    end
  end
end