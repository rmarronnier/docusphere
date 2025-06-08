require 'rails_helper'

RSpec.describe 'Coordination Workflow', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, password: 'password123') }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
  end

  describe 'Stakeholder coordination dashboard' do
    let!(:stakeholders) { create_list(:immo_promo_stakeholder, 3, project: project) }
    let!(:tasks) do
      stakeholders.map do |stakeholder|
        create(:immo_promo_task, 
          project: project, 
          assigned_to: stakeholder,
          start_date: Date.current,
          due_date: 1.week.from_now
        )
      end
    end

    it 'displays coordination overview' do
      visit immo_promo_engine.project_coordination_dashboard_path(project)
      
      expect(page).to have_content('Coordination des Intervenants')
      expect(page).to have_content(project.name)
      
      # Active interventions
      expect(page).to have_content('Interventions actives')
      expect(page).to have_content("#{tasks.count} interventions")
      
      # Stakeholder list
      stakeholders.each do |stakeholder|
        expect(page).to have_content(stakeholder.name)
      end
    end

    it 'allows filtering interventions' do
      visit immo_promo_engine.project_coordination_interventions_path(project)
      
      # Filter by stakeholder
      select stakeholders.first.name, from: 'stakeholder_filter'
      click_button 'Filtrer'
      
      expect(page).to have_content(stakeholders.first.name)
      expect(page).not_to have_content(stakeholders.last.name)
      
      # Filter by date range
      fill_in 'start_date', with: Date.current
      fill_in 'end_date', with: 3.days.from_now
      click_button 'Filtrer'
      
      expect(page).to have_css('.intervention-item')
    end

    it 'detects and displays conflicts' do
      # Create conflicting tasks
      stakeholder = stakeholders.first
      create(:immo_promo_task,
        project: project,
        assigned_to: stakeholder,
        start_date: Date.current,
        due_date: Date.current,
        title: 'Conflicting Task'
      )
      
      visit immo_promo_engine.project_coordination_conflicts_path(project)
      
      expect(page).to have_content('Conflits détectés')
      expect(page).to have_content('Surcharge de ressource')
      expect(page).to have_content(stakeholder.name)
      
      # Resolve conflict
      within('.conflict-item', match: :first) do
        click_button 'Résoudre'
      end
      
      select stakeholders.last.name, from: 'new_stakeholder'
      click_button 'Réassigner'
      
      expect(page).to have_content('Conflit résolu')
    end
  end

  describe 'Performance tracking' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project) }
    let!(:completed_tasks) do
      create_list(:immo_promo_task, 5,
        project: project,
        assigned_to: stakeholder,
        status: 'completed',
        completed_at: Date.current
      )
    end

    it 'displays performance metrics' do
      visit immo_promo_engine.project_coordination_performance_path(project)
      
      expect(page).to have_content('Performance des équipes')
      
      within("#stakeholder-#{stakeholder.id}") do
        expect(page).to have_content(stakeholder.name)
        expect(page).to have_content('5 tâches complétées')
        expect(page).to have_content('100%') # On-time rate
      end
      
      # View detailed performance
      click_link stakeholder.name
      
      expect(page).to have_content('Historique des interventions')
      expect(page).to have_css('.task-history-item', count: 5)
    end
  end

  describe 'Certification management' do
    let!(:stakeholder) { create(:immo_promo_stakeholder, project: project, role: 'electrician') }
    let!(:certification) do
      create(:immo_promo_certification,
        stakeholder: stakeholder,
        certification_type: 'qualification',
        expiry_date: 2.weeks.from_now
      )
    end

    it 'shows certification status and alerts' do
      visit immo_promo_engine.project_coordination_certifications_path(project)
      
      expect(page).to have_content('État des certifications')
      
      within('.certification-alert') do
        expect(page).to have_content('Expiration proche')
        expect(page).to have_content(stakeholder.name)
        expect(page).to have_content('Licence électrique')
      end
      
      # Send renewal reminder
      within("#certification-#{certification.id}") do
        click_button 'Envoyer rappel'
      end
      
      expect(page).to have_content('Rappel envoyé')
    end

    it 'validates certification requirements for tasks' do
      task = create(:immo_promo_task,
        project: project,
        title: 'Installation électrique',
        requires_certification: 'electrical_license'
      )
      
      visit immo_promo_engine.project_coordination_interventions_path(project)
      
      within("#task-#{task.id}") do
        expect(page).to have_css('.certification-required')
        
        # Try to assign to non-certified stakeholder
        non_certified = create(:immo_promo_stakeholder, project: project, role: 'plumber')
        select non_certified.name, from: 'assigned_to'
        
        expect(page).to have_content('Certification requise non disponible')
      end
    end
  end

  describe 'Timeline visualization' do
    let!(:phases) { create_list(:immo_promo_phase, 3, project: project) }
    let!(:tasks) do
      phases.flat_map do |phase|
        create_list(:immo_promo_task, 3, phase: phase, project: project)
      end
    end

    it 'displays interactive timeline' do
      visit immo_promo_engine.project_coordination_timeline_path(project)
      
      expect(page).to have_content('Timeline du projet')
      expect(page).to have_css('.gantt-chart')
      
      # Check phase display
      phases.each do |phase|
        expect(page).to have_content(phase.name)
      end
      
      # Interact with timeline
      find('.task-bar', match: :first).hover
      expect(page).to have_css('.task-tooltip')
      
      # Drag to reschedule (simulated)
      task_bar = find('.task-bar', match: :first)
      task_bar.drag_to(find('.timeline-date-future'))
      
      expect(page).to have_content('Tâche reprogrammée')
    end

    it 'highlights critical path' do
      visit immo_promo_engine.project_coordination_timeline_path(project)
      
      click_button 'Afficher chemin critique'
      
      expect(page).to have_css('.critical-path-task')
      expect(page).to have_content('Chemin critique')
      
      within('.critical-path-info') do
        expect(page).to have_content('Durée totale')
        expect(page).to have_content('jours')
      end
    end
  end

  describe 'Alert management' do
    it 'sends coordination alerts' do
      visit immo_promo_engine.project_coordination_dashboard_path(project)
      
      click_button 'Nouvelle alerte'
      
      within('#alert-modal') do
        select 'Intervention urgente', from: 'alert_type'
        fill_in 'message', with: 'Besoin urgent d\'intervention sur site'
        check 'stakeholder_1'
        check 'stakeholder_2'
        
        click_button 'Envoyer'
      end
      
      expect(page).to have_content('Alerte envoyée à 2 intervenants')
    end
  end

  describe 'Report generation' do
    let!(:stakeholders) { create_list(:immo_promo_stakeholder, 5, project: project) }
    let!(:tasks) { create_list(:immo_promo_task, 20, project: project) }

    it 'generates coordination report' do
      visit immo_promo_engine.project_coordination_dashboard_path(project)
      
      click_link 'Générer rapport'
      
      within('#report-options') do
        check 'include_performance'
        check 'include_certifications'
        check 'include_conflicts'
        
        select 'Mois en cours', from: 'period'
        select 'PDF', from: 'format'
        
        click_button 'Générer'
      end
      
      # Check download initiated
      expect(page.response_headers['Content-Type']).to include('application/pdf')
    end
  end

  describe 'Mobile responsiveness' do
    it 'works on mobile devices' do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size
      
      visit immo_promo_engine.project_coordination_dashboard_path(project)
      
      expect(page).to have_css('.mobile-menu-toggle')
      
      find('.mobile-menu-toggle').click
      expect(page).to have_css('.mobile-navigation')
      
      # Navigate to interventions
      within('.mobile-navigation') do
        click_link 'Interventions'
      end
      
      expect(page).to have_current_path(
        immo_promo_engine.project_coordination_interventions_path(project)
      )
      
      # Check responsive layout
      expect(page).to have_css('.intervention-card-mobile')
    end
  end

  describe 'Real-time updates' do
    it 'shows live intervention updates' do
      visit immo_promo_engine.project_coordination_dashboard_path(project)
      
      # Simulate another user creating a task
      in_browser(:two) do
        other_user = create(:user, organization: organization)
        login_as(other_user, scope: :user)
        
        visit immo_promo_engine.project_coordination_dashboard_path(project)
        
        click_button 'Nouvelle intervention'
        fill_in 'task_title', with: 'Intervention urgente'
        select stakeholders.first.name, from: 'assigned_to'
        fill_in 'start_date', with: Date.current
        
        click_button 'Créer'
      end
      
      # Check update appears in first browser
      expect(page).to have_content('Intervention urgente', wait: 5)
      expect(page).to have_css('.new-intervention-indicator')
    end
  end
end