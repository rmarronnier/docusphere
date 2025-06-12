# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ProjectDocumentsWidgetComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:chef_projet_profile) { create(:user_profile, user: user, profile_type: 'chef_projet', is_active: true) }
  let(:component) { described_class.new(user: user, max_projects: 3) }

  before do
    user.update(active_profile: chef_projet_profile)
  end

  describe '#initialize' do
    it 'initializes with user and max_projects' do
      expect(component).to be_a(described_class)
    end

    context 'when user is not chef_projet' do
      let(:other_profile) { create(:user_profile, user: user, profile_type: 'commercial', is_active: true) }
      
      before { user.update(active_profile: other_profile) }
      
      it 'loads empty projects array' do
        expect(component.send(:projects)).to be_empty
      end
    end
  end

  describe '#load_user_projects' do
    context 'when Immo::Promo::Project is defined' do
      before do
        stub_const('Immo::Promo::Project', Class.new(ApplicationRecord))
        stub_const('Immo::Promo::ProjectStakeholder', Class.new(ApplicationRecord))
        
        allow(Immo::Promo::Project).to receive(:joins).and_return(Immo::Promo::Project)
        allow(Immo::Promo::Project).to receive(:where).and_return(Immo::Promo::Project)
        allow(Immo::Promo::Project).to receive(:order).and_return(Immo::Promo::Project)
        allow(Immo::Promo::Project).to receive(:limit).and_return([])
      end
      
      it 'queries projects assigned to user' do
        expect(Immo::Promo::Project).to receive(:joins).with(:project_stakeholders)
        component.send(:load_user_projects)
      end
    end
    
    context 'when Immo::Promo::Project is not defined' do
      it 'returns empty array' do
        hide_const('Immo::Promo::Project')
        expect(component.send(:load_user_projects)).to eq([])
      end
    end
  end

  describe '#count_total_documents' do
    let(:project) { double('project', id: 1) }
    let(:space) { create(:space, name: 'Projet Test Project') }
    
    before do
      allow(component).to receive(:project_space_id).with(project).and_return(space.id)
    end
    
    it 'counts documents linked to project' do
      create_list(:document, 2, documentable: project)
      create_list(:document, 3, space: space)
      
      expect(component.send(:count_total_documents, project)).to eq(5)
    end
  end

  describe '#phase_document_breakdown' do
    let(:phase1) { double('phase', id: 1, name: 'Phase 1') }
    let(:phase2) { double('phase', id: 2, name: 'Phase 2') }
    let(:project) { double('project', phases: [phase1, phase2]) }
    
    it 'returns document count by phase' do
      create_list(:document, 2, documentable: phase1)
      create(:document, metadata: { phase_id: '2' })
      
      breakdown = component.send(:phase_document_breakdown, project)
      
      expect(breakdown['Phase 1']).to eq(2)
      expect(breakdown['Phase 2']).to eq(1)
    end
    
    it 'returns empty hash when project has no phases method' do
      project_without_phases = double('project')
      expect(component.send(:phase_document_breakdown, project_without_phases)).to eq({})
    end
  end

  describe '#project_status_color' do
    it 'returns correct colors for statuses' do
      expect(component.send(:project_status_color, 'in_progress')).to eq('text-green-600 bg-green-100')
      expect(component.send(:project_status_color, 'planning')).to eq('text-blue-600 bg-blue-100')
      expect(component.send(:project_status_color, 'on_hold')).to eq('text-yellow-600 bg-yellow-100')
      expect(component.send(:project_status_color, 'completed')).to eq('text-gray-600 bg-gray-100')
    end
  end

  describe '#document_type_icon' do
    it 'returns specific icon based on content type' do
      pdf_doc = create(:document, :with_pdf_file)
      expect(component.send(:document_type_icon, pdf_doc)).to eq('file-pdf')
    end
    
    it 'returns default icon for unknown types' do
      doc = double('document')
      expect(component.send(:document_type_icon, doc)).to eq('file')
    end
  end

  describe '#current_phase_name' do
    it 'returns current phase name' do
      phase = double('phase', name: 'Construction')
      project = double('project', current_phase: phase)
      
      expect(component.send(:current_phase_name, project)).to eq('Construction')
    end
    
    it 'returns Initialisation when no current phase' do
      project = double('project', current_phase: nil)
      expect(component.send(:current_phase_name, project)).to eq('Initialisation')
    end
    
    it 'returns Non définie when project has no current_phase method' do
      project = double('project')
      expect(component.send(:current_phase_name, project)).to eq('Non définie')
    end
  end

  describe '#phase_color' do
    it 'cycles through colors' do
      colors = %w[blue green purple pink yellow indigo red orange]
      
      (0..10).each do |i|
        color = component.send(:phase_color, i)
        expect(colors).to include(color)
      end
    end
  end

  describe '#has_urgent_documents?' do
    let(:project) { double('project', id: 1) }
    
    it 'returns true when pending documents exist' do
      allow(component).to receive(:documents_by_project).and_return({
        1 => { pending_count: 5 }
      })
      
      expect(component.send(:has_urgent_documents?, project)).to be_truthy
    end
    
    it 'returns false when no pending documents' do
      allow(component).to receive(:documents_by_project).and_return({
        1 => { pending_count: 0 }
      })
      
      expect(component.send(:has_urgent_documents?, project)).to be_falsey
    end
  end

  describe 'rendering' do
    it 'renders successfully with no projects' do
      render_inline(component)
      
      expect(page).to have_text('Documents par projet')
      expect(page).to have_text('Aucun projet actif')
      expect(page).to have_text("Vous n'êtes assigné à aucun projet")
    end
    
    context 'with mock projects' do
      let(:project1) do 
        double('project', 
          id: 1, 
          name: 'Projet Alpha',
          status: 'in_progress',
          current_phase: double('phase', name: 'Construction'),
          completion_percentage: 65
        )
      end
      
      let(:project2) do
        double('project',
          id: 2,
          name: 'Projet Beta', 
          status: 'planning',
          current_phase: nil,
          completion_percentage: 20
        )
      end
      
      before do
        allow(component).to receive(:projects).and_return([project1, project2])
        allow(component).to receive(:documents_by_project).and_return({
          1 => {
            recent: create_list(:document, 3, name: 'Doc Alpha'),
            total_count: 15,
            pending_count: 3,
            phase_breakdown: { 'Design' => 5, 'Construction' => 10 }
          },
          2 => {
            recent: [],
            total_count: 0,
            pending_count: 0,
            phase_breakdown: {}
          }
        })
        
        allow(component).to receive(:stats).and_return({
          total_projects: 2,
          total_documents: 15,
          pending_documents: 3,
          recent_uploads: 5
        })
      end
      
      it 'renders project information' do
        render_inline(component)
        
        expect(page).to have_text('Projet Alpha')
        expect(page).to have_text('Projet Beta')
        expect(page).to have_text('En cours')
        expect(page).to have_text('Planification')
        expect(page).to have_text('65% complété')
        expect(page).to have_text('Phase: Construction')
      end
      
      it 'shows document stats' do
        render_inline(component)
        
        expect(page).to have_text('15') # Total documents
        expect(page).to have_text('3')  # Pending
        expect(page).to have_text('5')  # Recent uploads
      end
      
      it 'shows phase breakdown' do
        render_inline(component)
        
        expect(page).to have_text('Design: 5')
        expect(page).to have_text('Construction: 10')
      end
      
      it 'shows empty state for project without documents' do
        render_inline(component)
        
        expect(page).to have_text('Aucun document pour ce projet')
      end
    end
  end
end