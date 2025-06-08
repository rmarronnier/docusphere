require 'rails_helper'

RSpec.describe Immo::Promo::ProjectCardComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  
  it 'renders project information' do
    render_inline(described_class.new(project: project))
    
    expect(page).to have_text(project.name)
    expect(page).to have_text(project.reference_number)
    expect(page).to have_text(project.project_type.humanize)
  end
  
  it 'displays progress percentage' do
    allow(project).to receive(:completion_percentage).and_return(75)
    
    render_inline(described_class.new(project: project))
    
    expect(page).to have_text('75%')
  end
  
  it 'shows budget information' do
    project.update(total_budget_cents: 5_000_000_00)
    
    render_inline(described_class.new(project: project))
    
    expect(page).to have_text('5 000 000')
  end
  
  it 'indicates project status' do
    project.update(status: 'construction')
    
    render_inline(described_class.new(project: project))
    
    expect(page).to have_css('.badge', text: 'Construction')
  end
  
  it 'shows days remaining' do
    allow(project).to receive(:days_remaining).and_return(45)
    
    render_inline(described_class.new(project: project))
    
    expect(page).to have_text('45 jours restants')
  end
  
  context 'when project is overdue' do
    it 'shows overdue warning' do
      allow(project).to receive(:days_remaining).and_return(-10)
      
      render_inline(described_class.new(project: project))
      
      expect(page).to have_css('.text-red-600')
      expect(page).to have_text('10 jours de retard')
    end
  end
end