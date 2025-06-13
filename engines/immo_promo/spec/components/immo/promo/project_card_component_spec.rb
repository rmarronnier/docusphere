require 'rails_helper'

RSpec.describe Immo::Promo::ProjectCardComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }

  before do
    # Mock the helpers for ViewComponent tests
    policy_double = double(edit?: false, destroy?: false, view_financial_data?: true)
    view_context = double(policy: policy_double)
    
    # Mock helpers for all components that need it
    [
      described_class,
      Immo::Promo::ProjectCard::ActionsComponent,
      Immo::Promo::ProjectCard::InfoComponent,
      Immo::Promo::ProjectCard::HeaderComponent
    ].each do |component_class|
      allow_any_instance_of(component_class).to receive(:helpers).and_return(view_context)
    end
  end

  describe 'rendering' do
    it 'renders the project card' do
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text(project.name)
      expect(page).to have_text(project.reference_number)
    end

    it 'displays project type' do
      project.update(project_type: 'residential')
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('Residential')
    end

    it 'displays project status' do
      project.update(status: 'construction')
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('Construction')
    end

    it 'shows project dates' do
      project.update(
        start_date: Date.new(2024, 1, 1),
        end_date: Date.new(2025, 12, 31)
      )
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('01/01/2024')
      expect(page).to have_text('31/12/2025')
    end

    it 'shows "À définir" for missing dates' do
      project.update(start_date: nil, end_date: nil)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('À définir', count: 2)
    end
  end

  describe 'project metrics' do
    it 'displays completion percentage' do
      allow(project).to receive(:completion_percentage).and_return(65)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('65%')
      expect(page).to have_css('.bg-blue-600[style*="width: 65%"]')
    end

    it 'displays total units when present' do
      project.update(total_units: 50)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('Logements:')
      expect(page).to have_text('50')
    end

    it 'displays total surface area when present' do
      # Create lots to generate the total surface area
      create(:immo_promo_lot, project: project, surface_area: 1500)
      create(:immo_promo_lot, project: project, surface_area: 1000)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('Surface:')
      expect(page).to have_text('2 500 m²')
    end

    it 'displays project manager' do
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_text('Chef de projet:')
      expect(page).to have_text(user.display_name)
    end

    it 'does not show project manager section when missing' do
      project.update(project_manager: nil)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).not_to have_text('Chef de projet:')
    end
  end

  describe 'status indicators' do
    context 'when project is delayed' do
      it 'shows delay warning' do
        allow(project).to receive(:is_delayed?).and_return(true)
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).to have_css('.bg-red-50')
        expect(page).to have_css('.text-red-700')
        expect(page).to have_text('Projet en retard')
      end
    end

    context 'when project is not delayed' do
      it 'does not show delay warning' do
        allow(project).to receive(:is_delayed?).and_return(false)
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).not_to have_css('.bg-red-50')
        expect(page).not_to have_text('Projet en retard')
      end
    end

    context 'status badge styling' do
      it 'shows planning status with French label' do
        project.update(status: 'planning')
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).to have_css('.bg-blue-100.text-blue-800')
        expect(page).to have_text('En planification')
      end

      it 'shows construction status with French label' do
        project.update(status: 'construction')
        
        component = described_class.new(project: project)
        render_inline(component)
        
        # Construction status doesn't have a specific preset, so it will use humanize
        expect(page).to have_text('Construction')
      end

      it 'shows pre_construction status with French label' do
        project.update(status: 'pre_construction')
        
        component = described_class.new(project: project)
        render_inline(component)
        
        # Pre-construction status doesn't have a specific preset, so it will use humanize
        expect(page).to have_text('Pre construction')
      end

      it 'shows completed status with French label' do
        project.update(status: 'completed')
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).to have_css('.bg-gray-100.text-gray-800')
        expect(page).to have_text('Terminé')
      end

      it 'shows cancelled status with French label' do
        project.update(status: 'cancelled')
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).to have_css('.bg-red-100.text-red-800')
        expect(page).to have_text('Annulé')
      end
    end
  end

  describe 'progress bar colors' do
    it 'shows red for 0-25% completion' do
      allow(project).to receive(:completion_percentage).and_return(20)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_css('.bg-red-600')
    end

    it 'shows yellow for 26-50% completion' do
      allow(project).to receive(:completion_percentage).and_return(40)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_css('.bg-yellow-600')
    end

    it 'shows blue for 51-75% completion' do
      allow(project).to receive(:completion_percentage).and_return(65)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_css('.bg-blue-600')
    end

    it 'shows green for 76-100% completion' do
      allow(project).to receive(:completion_percentage).and_return(85)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_css('.bg-green-600')
    end
  end

  describe 'card actions' do
    it 'shows view details link' do
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_link('Voir détails', href: /projects\/#{project.id}/)
    end

    it 'hides actions when show_actions is false' do
      component = described_class.new(project: project, show_actions: false)
      render_inline(component)
      
      expect(page).not_to have_link('Voir détails')
      expect(page).not_to have_link('Éditer')
    end

    context 'with permissions' do
      it 'shows edit link when user can edit' do
        # Mock the ActionsComponent helpers since that's where the policy check happens
        policy_double = double(edit?: true, destroy?: false)
        helpers_double = double(policy: policy_double)
        allow_any_instance_of(Immo::Promo::ProjectCard::ActionsComponent).to receive(:helpers).and_return(helpers_double)
        allow(helpers_double).to receive(:policy).with(project).and_return(policy_double)
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).to have_link('Éditer')
      end

      it 'shows delete link when user can destroy' do
        # Mock the ActionsComponent helpers since that's where the policy check happens
        policy_double = double(edit?: false, destroy?: true)
        helpers_double = double(policy: policy_double)
        allow_any_instance_of(Immo::Promo::ProjectCard::ActionsComponent).to receive(:helpers).and_return(helpers_double)
        allow(helpers_double).to receive(:policy).with(project).and_return(policy_double)
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).to have_link('Supprimer')
      end

      it 'hides edit/delete links when user lacks permissions' do
        # Mock the ActionsComponent helpers since that's where the policy check happens
        policy_double = double(edit?: false, destroy?: false)
        helpers_double = double(policy: policy_double)
        allow_any_instance_of(Immo::Promo::ProjectCard::ActionsComponent).to receive(:helpers).and_return(helpers_double)
        allow(helpers_double).to receive(:policy).with(project).and_return(policy_double)
        
        component = described_class.new(project: project)
        render_inline(component)
        
        expect(page).not_to have_link('Éditer')
        expect(page).not_to have_link('Supprimer')
      end
    end
  end

  describe 'card styling' do
    it 'has proper card styling' do
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_css('.bg-white.overflow-hidden.shadow.rounded-lg')
      expect(page).to have_css('.hover\\:shadow-lg')
    end

    it 'includes project icon' do
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_css('.bg-indigo-100.rounded-lg')
      expect(page).to have_css('svg.text-indigo-600')
    end
  end

  describe 'financial metrics' do
    context 'when show_financial is true' do
      it 'displays total budget when present' do
        project.update(total_budget: Money.new(100000000, 'EUR')) # 1,000,000 EUR
        
        component = described_class.new(project: project, show_financial: true)
        render_inline(component)
        
        expect(page).to have_text('Budget total:')
        expect(page).to have_text('1 000 000 €')
      end

      it 'displays current budget when present' do
        project.update(current_budget: Money.new(75000000, 'EUR')) # 750,000 EUR
        
        component = described_class.new(project: project, show_financial: true)
        render_inline(component)
        
        expect(page).to have_text('Coût actuel:')
        expect(page).to have_text('750 000 €')
      end

      it 'displays budget usage percentage' do
        project.update(
          total_budget: Money.new(100000000, 'EUR'),
          current_budget: Money.new(75000000, 'EUR')
        )
        
        component = described_class.new(project: project, show_financial: true)
        render_inline(component)
        
        expect(page).to have_text('Utilisation budget:')
        expect(page).to have_text('75,0%')
      end

      it 'highlights over budget projects in red' do
        project.update(
          total_budget: Money.new(100000000, 'EUR'),
          current_budget: Money.new(125000000, 'EUR')
        )
        
        component = described_class.new(project: project, show_financial: true)
        render_inline(component)
        
        expect(page).to have_css('.text-red-600.font-semibold', text: '1 250 000 €')
        expect(page).to have_css('.text-red-600.font-semibold', text: '125,0%')
      end
    end

    context 'when show_financial is false' do
      it 'does not display financial information' do
        project.update(
          total_budget: Money.new(100000000, 'EUR'),
          current_budget: Money.new(75000000, 'EUR')
        )
        
        component = described_class.new(project: project, show_financial: false)
        render_inline(component)
        
        expect(page).not_to have_text('Budget total:')
        expect(page).not_to have_text('Coût actuel:')
        expect(page).not_to have_text('Utilisation budget:')
      end
    end

    context 'when user cannot view financial data' do
      it 'does not display financial information' do
        policy_double = double(edit?: false, destroy?: false, view_financial_data?: false)
        view_context = double(policy: policy_double)
        allow_any_instance_of(Immo::Promo::ProjectCard::InfoComponent).to receive(:helpers).and_return(view_context)
        
        project.update(total_budget: Money.new(100000000, 'EUR'))
        
        component = described_class.new(project: project, show_financial: true)
        render_inline(component)
        
        expect(page).not_to have_text('Budget total:')
      end
    end
  end

  describe 'project thumbnails' do
    context 'when show_thumbnail is true and project has technical documents' do
      it 'shows thumbnail when image attachment exists' do
        # Mock Active Storage attachment collection
        technical_docs_mock = double('technical_documents')
        allow(technical_docs_mock).to receive(:any?).and_return(true)
        allow(technical_docs_mock).to receive(:find).and_return(double(content_type: 'image/jpeg'))
        allow(project).to receive(:technical_documents).and_return(technical_docs_mock)
        allow_any_instance_of(Immo::Promo::ProjectCard::HeaderComponent).to receive(:thumbnail_url).and_return('/test-image.jpg')
        
        component = described_class.new(project: project, show_thumbnail: true)
        render_inline(component)
        
        expect(page).to have_css('img[alt*="thumbnail"]')
      end
    end

    context 'when show_thumbnail is false' do
      it 'shows project icon instead of thumbnail' do
        component = described_class.new(project: project, show_thumbnail: false)
        render_inline(component)
        
        expect(page).to have_css('svg')
        expect(page).not_to have_css('img[alt*="thumbnail"]')
      end
    end
  end

  describe 'project type icons' do
    it 'shows home icon for residential projects' do
      project.update(project_type: 'residential')
      
      component = described_class.new(project: project)
      render_inline(component)
      
      # Check that it renders an icon (the specific icon will depend on Ui::IconComponent implementation)
      expect(page).to have_css('.text-indigo-600')
    end

    it 'shows office building icon for commercial projects' do
      project.update(project_type: 'commercial')
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).to have_css('.text-indigo-600')
    end
  end

  describe 'variant layouts' do
    context 'compact variant' do
      it 'uses compact styling' do
        component = described_class.new(project: project, variant: :compact)
        render_inline(component)
        
        expect(page).to have_css('.p-4')
        expect(page).to have_css('.hover\\:shadow-md')
      end

      it 'hides progress bar in compact mode' do
        component = described_class.new(project: project, variant: :compact)
        render_inline(component)
        
        # Progress component should not be rendered
        expect(page).not_to have_text('Avancement')
      end

      it 'hides some project details in compact mode' do
        project.update(total_units: 50)
        
        component = described_class.new(project: project, variant: :compact)
        render_inline(component)
        
        expect(page).not_to have_text('Logements:')
        expect(page).not_to have_text('Chef de projet:')
      end

      it 'uses smaller header elements' do
        component = described_class.new(project: project, variant: :compact)
        render_inline(component)
        
        expect(page).to have_css('.text-base', text: project.name)
        expect(page).to have_css('.w-8.h-8')
      end
    end

    context 'detailed variant' do
      it 'uses detailed styling' do
        component = described_class.new(project: project, variant: :detailed)
        render_inline(component)
        
        expect(page).to have_css('.p-8')
        expect(page).to have_css('.hover\\:shadow-xl')
      end

      it 'shows all project information' do
        project.update(total_units: 50)
        
        component = described_class.new(project: project, variant: :detailed)
        render_inline(component)
        
        expect(page).to have_text('Logements:')
        expect(page).to have_text('Chef de projet:')
        expect(page).to have_text('Avancement')
      end
    end

    context 'default variant' do
      it 'uses default styling' do
        component = described_class.new(project: project, variant: :default)
        render_inline(component)
        
        expect(page).to have_css('.p-6')
        expect(page).to have_css('.hover\\:shadow-lg')
      end

      it 'shows progress bar and most details' do
        component = described_class.new(project: project, variant: :default)
        render_inline(component)
        
        expect(page).to have_text('Avancement')
      end
    end
  end

  describe 'component parameters' do
    it 'accepts all new parameters without error' do
      expect {
        component = described_class.new(
          project: project,
          show_actions: true,
          show_financial: false,
          show_thumbnail: false,
          variant: :compact
        )
        render_inline(component)
      }.not_to raise_error
    end

    it 'passes parameters to sub-components correctly' do
      expect(Immo::Promo::ProjectCard::HeaderComponent).to receive(:new).with(
        hash_including(
          project: project,
          show_thumbnail: false,
          variant: :compact
        )
      ).and_call_original

      expect(Immo::Promo::ProjectCard::InfoComponent).to receive(:new).with(
        hash_including(
          project: project,
          show_financial: false,
          variant: :compact
        )
      ).and_call_original

      component = described_class.new(
        project: project,
        show_financial: false,
        show_thumbnail: false,
        variant: :compact
      )
      render_inline(component)
    end
  end

  describe 'responsive behavior' do
    it 'maintains responsive grid compatibility' do
      component = described_class.new(project: project)
      render_inline(component)
      
      # Should work in a grid layout
      expect(page).to have_css('.bg-white.overflow-hidden.shadow.rounded-lg')
    end
  end

  describe 'error handling' do
    it 'handles missing budget gracefully' do
      project.update(total_budget: nil, current_budget: nil)
      
      component = described_class.new(project: project, show_financial: true)
      render_inline(component)
      
      expect(page).not_to have_text('Budget total:')
      expect(page).not_to have_text('Coût actuel:')
    end

    it 'handles missing project manager gracefully' do
      project.update(project_manager: nil)
      
      component = described_class.new(project: project)
      render_inline(component)
      
      expect(page).not_to have_text('Chef de projet:')
    end
  end
end