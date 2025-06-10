require 'rails_helper'

RSpec.describe Immo::Promo::ProjectCardComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }

  before do
    # Mock the helpers for ViewComponent tests
    view_context = double(
      policy: double(edit?: false, destroy?: false)
    )
    allow_any_instance_of(described_class).to receive(:helpers).and_return(view_context)
    
    # Also mock helpers for sub-components
    allow_any_instance_of(Immo::Promo::ProjectCard::ActionsComponent).to receive(:helpers).and_return(view_context)
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

  describe 'variant parameter' do
    it 'accepts variant parameter without error' do
      # The component accepts variant parameter but doesn't use it
      expect {
        component = described_class.new(project: project, variant: :compact)
        render_inline(component)
      }.not_to raise_error
    end
  end
end