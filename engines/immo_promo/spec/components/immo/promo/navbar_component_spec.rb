require 'rails_helper'

RSpec.describe Immo::Promo::NavbarComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, role: 'admin') }
  let(:project) { create(:immo_promo_project, organization: organization) }

  before do
    allow_any_instance_of(described_class).to receive(:current_user).and_return(user)
  end

  describe 'rendering' do
    it 'renders the navigation bar' do
      component = described_class.new(current_user: user, current_project: nil)
      render_inline(component)
      
      expect(page).to have_css('nav.bg-white')
      expect(page).to have_link('Immo::Promo')
    end

    context 'when on dashboard' do
      it 'highlights dashboard link' do
        allow_any_instance_of(described_class).to receive(:on_dashboard?).and_return(true)
        allow_any_instance_of(Immo::Promo::Navbar::NavigationComponent).to receive(:on_dashboard?).and_return(true)
        
        component = described_class.new(current_user: user, current_project: nil)
        render_inline(component)
        
        expect(page).to have_css('a.border-blue-500', text: 'Tableau de bord')
      end
    end

    context 'when viewing a project' do
      it 'shows project name in breadcrumb' do
        component = described_class.new(current_user: user, current_project: project)
        render_inline(component)
        
        expect(page).to have_link(project.name)
      end

      it 'shows project-specific actions' do
        allow_any_instance_of(described_class).to receive(:on_project_view?).and_return(true)
        
        component = described_class.new(current_user: user, current_project: project)
        render_inline(component)
        
        expect(page).to have_css('[title="Intervenants"]')
        expect(page).to have_css('[title="Autorisations"]')
        expect(page).to have_css('[title="Budget"]')
      end
    end
  end

  describe 'permissions' do
    context 'when user can create projects' do
      it 'shows new project button' do
        allow_any_instance_of(described_class).to receive(:can_create_project?).and_return(true)
        
        component = described_class.new(current_user: user, current_project: nil)
        render_inline(component)
        
        expect(page).to have_button('Nouveau projet')
      end
    end

    context 'when user cannot create projects' do
      it 'does not show new project button' do
        # Mock the NewProjectButtonComponent's permission check
        allow_any_instance_of(Immo::Promo::Navbar::NewProjectButtonComponent).to receive(:can_create_project?).and_return(false)
        
        component = described_class.new(current_user: user, current_project: nil)
        render_inline(component)
        
        expect(page).not_to have_button('Nouveau projet')
      end
    end

    context 'when user can edit project' do
      it 'shows edit button' do
        # Mock the ProjectActionsComponent's permission check
        allow_any_instance_of(Immo::Promo::Navbar::ProjectActionsComponent).to receive(:can_edit_project?).and_return(true)
        
        component = described_class.new(current_user: user, current_project: project)
        render_inline(component)
        
        expect(page).to have_link('Modifier')
      end
    end

    context 'when user cannot manage stakeholders' do
      it 'does not show stakeholders link' do
        # Mock the ProjectActionsComponent's permission check
        allow_any_instance_of(Immo::Promo::Navbar::ProjectActionsComponent).to receive(:can_manage_stakeholders?).and_return(false)
        
        component = described_class.new(current_user: user, current_project: project)
        render_inline(component)
        
        expect(page).not_to have_css('[title="Intervenants"]')
      end
    end
  end

  describe 'new project modal' do
    it 'renders the modal form' do
      component = described_class.new(current_user: user, current_project: nil)
      render_inline(component)
      
      expect(page).to have_css('form[action*="projects"]')
      expect(page).to have_field('project_name')
      expect(page).to have_field('project_reference')
      expect(page).to have_select('project_type')
      expect(page).to have_field('project_start_date')
      expect(page).to have_field('project_end_date')
    end

    it 'includes project type options' do
      component = described_class.new(current_user: user, current_project: nil)
      render_inline(component)
      
      within 'select#project_type' do
        expect(page).to have_css('option[value="residential"]', text: 'Résidentiel')
        expect(page).to have_css('option[value="commercial"]', text: 'Commercial')
        expect(page).to have_css('option[value="mixed"]', text: 'Mixte')
        expect(page).to have_css('option[value="industrial"]', text: 'Industriel')
      end
    end
  end

  describe 'mobile menu' do
    it 'renders mobile navigation' do
      component = described_class.new(current_user: user, current_project: nil)
      render_inline(component)
      
      expect(page).to have_css('.sm\\:hidden[data-immo-promo-navbar-target="mobileMenu"]')
      within '.sm\\:hidden' do
        expect(page).to have_link('Tableau de bord')
        expect(page).to have_link('Projets')
      end
    end
  end

  describe 'route helpers' do
    it 'uses engine route helpers with helpers prefix' do
      component = described_class.new(current_user: user, current_project: project)
      render_inline(component)
      
      # Check that links contain the engine prefix /immo/promo
      expect(page).to have_link('Tableau de bord', href: /\/immo\/promo/)
      expect(page).to have_link('Projets', href: /\/immo\/promo/)
    end
  end
end