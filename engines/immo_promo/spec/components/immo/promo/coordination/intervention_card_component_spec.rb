require 'rails_helper'

RSpec.describe Immo::Promo::Coordination::InterventionCardComponent, type: :component do
  let(:project) { create(:immo_promo_project) }
  let(:phase) { create(:immo_promo_phase, project: project) }
  let(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
  let(:user) { create(:user, organization: project.organization) }
  
  let(:intervention) do
    create(:immo_promo_task,
      phase: phase,
      assigned_to: user,
      stakeholder: stakeholder,
      name: 'Installation électrique',
      task_type: 'execution',
      status: 'in_progress',
      priority: 'high',
      start_date: 2.days.ago,
      end_date: 3.days.from_now,
      estimated_hours: 24,
      checklist: { required_skills: ['Électricité', 'Sécurité'] }
    )
  end

  describe 'rendering' do
    subject(:component) { described_class.new(intervention: intervention) }

    it 'renders the intervention card' do
      render_inline(component)

      expect(page).to have_content(intervention.name)
      expect(page).to have_content(user.display_name)
      expect(page).to have_content(phase.name)
      expect(page).to have_content('Exécution')
    end

    it 'displays intervention status' do
      render_inline(component)

      expect(page).to have_content('En cours')
    end

    it 'shows priority badge for high/critical priorities' do
      render_inline(component)

      expect(page).to have_content('Élevée')
    end

    it 'displays required skills' do
      render_inline(component)

      expect(page).to have_content('Électricité')
      expect(page).to have_content('Sécurité')
    end
  end

  describe 'variants' do
    context 'when variant is current' do
      subject(:component) { described_class.new(intervention: intervention, variant: :current) }

      it 'applies current intervention styling' do
        render_inline(component)

        expect(page).to have_css('.border-green-200.bg-green-50')
        expect(page).to have_content('Échéance')
      end

      it 'shows days remaining' do
        render_inline(component)

        expect(page).to have_content('jours restants')
      end
    end

    context 'when variant is upcoming' do
      let(:upcoming_intervention) do
        create(:immo_promo_task,
          phase: phase,
          assigned_to: user,
          name: 'Inspection finale',
          status: 'pending',
          start_date: 5.days.from_now,
          end_date: 7.days.from_now
        )
      end

      subject(:component) { described_class.new(intervention: upcoming_intervention, variant: :upcoming) }

      it 'applies upcoming intervention styling' do
        render_inline(component)

        expect(page).to have_css('.border-blue-200.bg-blue-50')
        expect(page).to have_content('Début prévu')
      end
    end

    context 'when variant is overdue' do
      let(:overdue_intervention) do
        create(:immo_promo_task,
          phase: phase,
          assigned_to: user,
          name: 'Tâche en retard',
          status: 'in_progress',
          start_date: 3.days.ago,
          end_date: 2.days.ago
        )
      end

      subject(:component) { described_class.new(intervention: overdue_intervention, variant: :overdue) }

      it 'applies overdue intervention styling' do
        render_inline(component)

        expect(page).to have_css('.border-red-200.bg-red-50')
      end

      it 'shows overdue indicator' do
        # Mock the is_overdue? method to return true
        allow(overdue_intervention).to receive(:is_overdue?).and_return(true)
        
        render_inline(component)

        # Look for the exclamation triangle icon in the overdue warning
        expect(page).to have_css('[class*="text-red-500"]')
      end
    end

    context 'when variant is completed' do
      let(:completed_intervention) do
        create(:immo_promo_task,
          phase: phase,
          assigned_to: user,
          name: 'Tâche terminée',
          status: 'completed',
          start_date: 2.days.ago,
          end_date: 1.day.ago
        )
      end

      subject(:component) { described_class.new(intervention: completed_intervention, variant: :completed) }

      it 'applies completed intervention styling' do
        render_inline(component)

        expect(page).to have_css('.border-gray-200.bg-gray-50')
        expect(page).to have_content('Terminée')
      end
    end
  end

  describe 'progress display' do
    context 'when show_progress is true and intervention has progress' do
      let(:progressing_intervention) do
        create(:immo_promo_task,
          phase: phase,
          assigned_to: user,
          estimated_hours: 10
        )
      end

      before do
        # Mock le pourcentage de progression
        allow(progressing_intervention).to receive(:completion_percentage).and_return(65)
      end

      subject(:component) { described_class.new(intervention: progressing_intervention, show_progress: true) }

      it 'renders progress indicator' do
        render_inline(component)

        # Le composant ProgressIndicatorComponent devrait être rendu
        expect(page).to have_content('65')
      end
    end

    context 'when show_progress is false' do
      subject(:component) { described_class.new(intervention: intervention, show_progress: false) }

      it 'does not render progress indicator' do
        render_inline(component)

        # Ne devrait pas inclure de barre de progression - looking for specific progress component class
        expect(page).not_to have_css('.progress, [class*="progress"]')
      end
    end
  end

  describe 'timeline display' do
    context 'when show_timeline is true' do
      subject(:component) { described_class.new(intervention: intervention, show_timeline: true) }

      it 'renders timeline mini' do
        render_inline(component)

        expect(page).to have_content('Début')
        expect(page).to have_content('Fin prévue')
      end

      it 'shows timeline status indicators' do
        render_inline(component)

        expect(page).to have_css('.w-2.h-2.rounded-full')
      end
    end

    context 'when show_timeline is false' do
      subject(:component) { described_class.new(intervention: intervention, show_timeline: false) }

      it 'does not render timeline' do
        render_inline(component)

        expect(page).not_to have_content('Début:')
        expect(page).not_to have_content('Fin prévue:')
      end
    end
  end

  describe 'size variants' do
    context 'when size is small' do
      subject(:component) { described_class.new(intervention: intervention, size: :small) }

      it 'applies small size styling' do
        render_inline(component)

        expect(page).to have_css('.p-2.text-sm')
      end
    end

    context 'when size is large' do
      subject(:component) { described_class.new(intervention: intervention, size: :large) }

      it 'applies large size styling' do
        render_inline(component)

        expect(page).to have_css('.p-4')
      end
    end

    context 'when size is medium (default)' do
      subject(:component) { described_class.new(intervention: intervention, size: :medium) }

      it 'applies medium size styling' do
        render_inline(component)

        expect(page).to have_css('.p-3')
      end
    end
  end

  describe 'task type handling' do
    context 'with different task types' do
      [
        { type: 'planning', icon: 'calendar', text: 'Planification' },
        { type: 'execution', icon: 'cog-8-tooth', text: 'Exécution' },
        { type: 'review', icon: 'eye', text: 'Révision' },
        { type: 'approval', icon: 'check-circle', text: 'Approbation' },
        { type: 'milestone', icon: 'flag', text: 'Jalon' },
        { type: 'administrative', icon: 'document-text', text: 'Administratif' },
        { type: 'technical', icon: 'wrench-screwdriver', text: 'Technique' }
      ].each do |test_case|
        it "displays correct icon and text for #{test_case[:type]} task type" do
          intervention.update!(task_type: test_case[:type])
          component = described_class.new(intervention: intervention)

          render_inline(component)

          expect(page).to have_content(test_case[:text])
          # Icon assertion would depend on how Ui::IconComponent works
        end
      end
    end
  end

  describe 'priority handling' do
    context 'with different priorities' do
      [
        { priority: 'critical', text: 'Critique', color: 'bg-red-100 text-red-800' },
        { priority: 'high', text: 'Élevée', color: 'bg-orange-100 text-orange-800' },
        { priority: 'medium', text: 'Moyenne', color: 'bg-yellow-100 text-yellow-800' },
        { priority: 'low', text: 'Faible', color: 'bg-gray-100 text-gray-800' }
      ].each do |test_case|
        it "displays correct badge for #{test_case[:priority]} priority" do
          intervention.update!(priority: test_case[:priority])
          component = described_class.new(intervention: intervention)

          render_inline(component)

          if test_case[:priority].in?(['high', 'critical'])
            expect(page).to have_content(test_case[:text])
          else
            # Low and medium priorities don't show badges
            expect(page).not_to have_content(test_case[:text])
          end
        end
      end
    end
  end

  describe 'status handling' do
    context 'with different statuses' do
      [
        { status: 'completed', text: 'Terminée', color: 'text-green-600' },
        { status: 'in_progress', text: 'En cours', color: 'text-blue-600' },
        { status: 'blocked', text: 'Bloquée', color: 'text-red-600' },
        { status: 'pending', text: 'En attente', color: 'text-yellow-600' }
      ].each do |test_case|
        it "displays correct status for #{test_case[:status]}" do
          intervention.update!(status: test_case[:status])
          component = described_class.new(intervention: intervention)

          render_inline(component)

          expect(page).to have_content(test_case[:text])
        end
      end
    end
  end

  describe 'date formatting' do
    context 'with current intervention' do
      subject(:component) { described_class.new(intervention: intervention, variant: :current) }

      it 'shows due date with relative information' do
        render_inline(component)

        expect(page).to have_content('Échéance')
        # Should show formatted date with relative time
      end
    end

    context 'with upcoming intervention' do
      let(:upcoming_intervention) do
        create(:immo_promo_task,
          phase: phase,
          assigned_to: user,
          start_date: Date.current + 1.day
        )
      end

      subject(:component) { described_class.new(intervention: upcoming_intervention, variant: :upcoming) }

      it 'shows start date with "Demain" indicator' do
        render_inline(component)

        expect(page).to have_content('Début prévu')
        expect(page).to have_content('Demain')
      end
    end
  end

  describe 'skill requirements' do
    context 'with multiple skills' do
      let(:skilled_intervention) do
        create(:immo_promo_task,
          phase: phase,
          assigned_to: user,
          checklist: { 
            required_skills: ['Électricité', 'Plomberie', 'Sécurité', 'Coordination', 'Gestion'] 
          }
        )
      end

      subject(:component) { described_class.new(intervention: skilled_intervention) }

      it 'displays first 3 skills and shows count for remaining' do
        render_inline(component)

        expect(page).to have_content('Électricité')
        expect(page).to have_content('Plomberie')
        expect(page).to have_content('Sécurité')
        expect(page).to have_content('+2')
      end
    end

    context 'without skills' do
      let(:no_skills_intervention) do
        create(:immo_promo_task,
          phase: phase,
          assigned_to: user,
          checklist: {}
        )
      end

      subject(:component) { described_class.new(intervention: no_skills_intervention) }

      it 'does not display skills section' do
        render_inline(component)

        expect(page).not_to have_css('.bg-blue-100.text-blue-800')
      end
    end
  end

  describe 'extra classes' do
    subject(:component) { described_class.new(intervention: intervention, extra_classes: 'shadow-lg border-2') }

    it 'applies extra classes to the card' do
      render_inline(component)

      expect(page).to have_css('.shadow-lg.border-2')
    end
  end

  describe 'prerequisite handling' do
    let(:blocked_intervention) do
      intervention = create(:immo_promo_task,
        phase: phase,
        assigned_to: user,
        name: 'Tâche bloquée'
      )
      
      # Mock the can_start? method
      allow(intervention).to receive(:can_start?).and_return(false)
      intervention
    end

    subject(:component) { described_class.new(intervention: blocked_intervention, variant: :current) }

    it 'shows prerequisite warning' do
      render_inline(component)

      expect(page).to have_content('Prérequis non remplis')
    end
  end
end