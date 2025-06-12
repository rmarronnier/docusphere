require 'rails_helper'

RSpec.describe Dashboard::ProjectDocumentsWidgetComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:user_profile) { create(:user_profile, user: user, profile_type: 'chef_projet', active: true) }
  
  before do
    user.update!(active_profile: user_profile)
  end

  context 'when ImmoPromo engine is available' do
    let!(:project1) do
      create(:immo_promo_project, 
        name: 'Résidence Les Jardins',
        project_manager: user,
        organization: organization,
        status: 'construction'
      )
    end
    
    let!(:project2) do
      create(:immo_promo_project,
        name: 'Centre Commercial Atlantis', 
        project_manager: user,
        organization: organization,
        status: 'planning'
      )
    end

    let!(:phase1) { create(:immo_promo_phase, project: project1, name: 'Gros œuvre', phase_type: 'construction') }
    let!(:phase2) { create(:immo_promo_phase, project: project2, name: 'Études préliminaires', phase_type: 'studies') }

    let!(:document1) do
      create(:document,
        title: 'Plan de masse.pdf',
        documentable: project1,
        uploaded_by: user,
        document_category: 'plan',
        status: 'published',
        created_at: 2.hours.ago
      )
    end

    let!(:document2) do
      create(:document,
        title: 'Permis de construire.pdf',
        documentable: project1,
        uploaded_by: user,
        document_category: 'permit',
        status: 'under_review',
        created_at: 1.day.ago
      )
    end

    let!(:document3) do
      create(:document,
        title: 'Étude de sol.pdf',
        documentable: project2,
        uploaded_by: user,
        document_category: 'technical',
        status: 'published',
        created_at: 3.days.ago
      )
    end

    it 'renders the widget header' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Documents par projet')
      expect(page).to have_text('2 projets actifs')
    end

    it 'displays global statistics' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('3') # Total documents
      expect(page).to have_text('Documents totaux')
      expect(page).to have_text('1') # Pending documents (under_review)
      expect(page).to have_text('En attente')
      expect(page).to have_text('1') # Recent uploads (within 1 week)
      expect(page).to have_text('Cette semaine')
    end

    it 'displays project information with status and progress' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_link('Résidence Les Jardins')
      expect(page).to have_link('Centre Commercial Atlantis')
      expect(page).to have_text('Construction')
      expect(page).to have_text('Planification')
    end

    it 'provides quick action buttons' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_link(title: 'Uploader un document')
      expect(page).to have_link(title: 'Voir tous les documents')
    end

    it 'shows urgent indicators for projects with pending documents' do
      render_inline(described_class.new(user: user))
      
      # Should show urgent indicator for project1 which has under_review document
      within find('h4', text: 'Résidence Les Jardins').find(:xpath, '..') do
        expect(page).to have_css('.animate-pulse', count: 1)
      end
    end

    it 'handles projects with no documents gracefully' do
      # Create project without documents
      project_without_docs = create(:immo_promo_project,
        name: 'Projet Sans Documents',
        project_manager: user,
        organization: organization,
        status: 'planning'
      )

      render_inline(described_class.new(user: user, max_projects: 3))
      
      expect(page).to have_text('Projet Sans Documents')
      expect(page).to have_text('Aucun document pour ce projet')
    end

    it 'provides link to view all projects' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_link('Voir tous mes projets')
    end

    context 'with different user profiles' do
      context 'when user is direction' do
        let(:user_profile) { create(:user_profile, user: user, profile_type: 'direction', active: true) }
        let!(:other_project) do
          create(:immo_promo_project,
            name: 'Autre Projet',
            organization: organization,
            status: 'construction'
          )
        end

        before { user.update!(active_profile: user_profile) }

        it 'shows all organization projects' do
          render_inline(described_class.new(user: user))
          
          expect(page).to have_text('3 projets actifs') # Including other_project
          expect(page).to have_text('Autre Projet')
        end
      end
    end

    context 'with limit parameter' do
      let!(:additional_projects) do
        create_list(:immo_promo_project, 5,
          project_manager: user,
          organization: organization,
          status: 'planning'
        )
      end

      it 'respects the max_projects limit' do
        render_inline(described_class.new(user: user, max_projects: 3))
        
        # Should show only 3 projects despite having more
        expect(page).to have_css('.p-4', count: 3) # Project containers
      end
    end
  end

  context 'when ImmoPromo engine is not available' do
    before do
      # Stub to simulate engine not being available
      allow(Object).to receive(:const_defined?).with('Immo::Promo::Project').and_return(false)
    end

    it 'shows empty state' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Aucun projet actif')
      expect(page).to have_text('Vous n\'êtes assigné à aucun projet pour le moment.')
    end
  end

  context 'when user has no active profile' do
    before do
      user.update!(active_profile: nil)
    end

    it 'shows empty state' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Aucun projet actif')
    end
  end
end