require 'rails_helper'

RSpec.describe Immo::Promo::TimelineComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:phases) { [] }

  describe 'rendering' do
    context 'with no phases' do
      it 'renders empty timeline message' do
        component = described_class.new(phases: [])
        render_inline(component)
        
        expect(page).to have_text('Aucune phase définie')
      end
    end

    context 'with phases' do
      let(:phase1) { create(:immo_promo_phase, project: project, name: 'Planification', position: 1, status: 'completed') }
      let(:phase2) { create(:immo_promo_phase, project: project, name: 'Permis', position: 2, status: 'in_progress') }
      let(:phase3) { create(:immo_promo_phase, project: project, name: 'Construction', position: 3, status: 'pending') }
      let(:phases) { [phase1, phase2, phase3] }

      it 'renders all phases' do
        component = described_class.new(phases: phases)
        render_inline(component)
        
        expect(page).to have_text('Planification')
        expect(page).to have_text('Permis')
        expect(page).to have_text('Construction')
      end

      it 'displays phase statuses correctly' do
        component = described_class.new(phases: phases)
        render_inline(component)
        
        # Completed phase should have check icon
        within "[data-phase-id='#{phase1.id}']" do
          expect(page).to have_css('.bg-green-500')
          expect(page).to have_css('svg') # Check icon
        end
        
        # In progress phase should have different styling
        within "[data-phase-id='#{phase2.id}']" do
          expect(page).to have_css('.bg-blue-500')
        end
        
        # Pending phase should have gray styling
        within "[data-phase-id='#{phase3.id}']" do
          expect(page).to have_css('.bg-gray-300')
        end
      end

      it 'shows phase dates' do
        phase1.update(start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 3, 31))
        
        component = described_class.new(phases: [phase1])
        render_inline(component)
        
        expect(page).to have_text('01/01/2024')
        expect(page).to have_text('31/03/2024')
      end

      it 'shows phase progress' do
        phase2.update(task_completion_percentage: 75)
        
        component = described_class.new(phases: [phase2])
        render_inline(component)
        
        expect(page).to have_text('75%')
        expect(page).to have_css('.bg-blue-600[style*="width: 75%"]')
      end
    end

    context 'with delayed phases' do
      let(:delayed_phase) do
        create(:immo_promo_phase, 
               project: project, 
               name: 'Phase en retard',
               status: 'in_progress',
               end_date: 1.week.ago)
      end

      it 'shows delay indicator' do
        component = described_class.new(phases: [delayed_phase])
        render_inline(component)
        
        expect(page).to have_css('.text-red-600')
        expect(page).to have_text('En retard')
      end
    end

    context 'with critical phases' do
      let(:critical_phase) do
        create(:immo_promo_phase, 
               project: project, 
               name: 'Phase critique',
               is_critical: true)
      end

      it 'shows critical indicator' do
        component = described_class.new(phases: [critical_phase])
        render_inline(component)
        
        expect(page).to have_css('.border-red-500')
        expect(page).to have_text('Critique')
      end
    end
  end

  describe 'phase connections' do
    let(:phase1) { create(:immo_promo_phase, project: project, position: 1) }
    let(:phase2) { create(:immo_promo_phase, project: project, position: 2) }
    let(:phases) { [phase1, phase2] }

    it 'renders connection lines between phases' do
      component = described_class.new(phases: phases)
      render_inline(component)
      
      expect(page).to have_css('.timeline-connector')
    end
  end

  describe 'interactive features' do
    let(:phase) { create(:immo_promo_phase, project: project) }

    it 'makes phase names clickable' do
      component = described_class.new(phases: [phase])
      render_inline(component)
      
      expect(page).to have_link(phase.name)
    end

    it 'shows task count' do
      create_list(:immo_promo_task, 5, phase: phase)
      
      component = described_class.new(phases: [phase])
      render_inline(component)
      
      expect(page).to have_text('5 tâches')
    end
  end

  describe 'responsive design' do
    let(:phases) { create_list(:immo_promo_phase, 3, project: project) }

    it 'uses responsive classes' do
      component = described_class.new(phases: phases)
      render_inline(component)
      
      expect(page).to have_css('.sm\\:flex')
      expect(page).to have_css('.md\\:grid')
    end
  end

  describe 'empty states' do
    it 'handles phases without dates gracefully' do
      phase = create(:immo_promo_phase, project: project, start_date: nil, end_date: nil)
      
      component = described_class.new(phases: [phase])
      render_inline(component)
      
      expect(page).to have_text('Dates non définies')
    end

    it 'handles phases without description' do
      phase = create(:immo_promo_phase, project: project, description: nil)
      
      component = described_class.new(phases: [phase])
      render_inline(component)
      
      expect(page).not_to have_css('.phase-description')
    end
  end
end