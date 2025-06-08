require 'rails_helper'

RSpec.describe 'Permit Workflow', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, password: 'password123') }
  let(:project) { 
    create(:immo_promo_project, 
      organization: organization, 
      project_manager: user,
      project_type: 'residential',
      total_area_sqm: 3000
    ) 
  }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
  end

  describe 'Permit workflow dashboard' do
    let!(:permits) do
      [
        create(:immo_promo_permit, project: project, permit_type: 'demolition', status: 'approved'),
        create(:immo_promo_permit, project: project, permit_type: 'construction', status: 'draft'),
        create(:immo_promo_permit, project: project, permit_type: 'environmental', status: 'submitted')
      ]
    end

    it 'displays permit overview and status' do
      visit immo_promo_engine.project_permit_workflow_dashboard_path(project)
      
      expect(page).to have_content('Workflow Permis & Autorisations')
      expect(page).to have_content(project.name)
      
      # Status summary
      expect(page).to have_content('1 approuvé')
      expect(page).to have_content('1 en cours')
      expect(page).to have_content('1 brouillon')
      
      # Compliance score
      expect(page).to have_css('.compliance-score')
      expect(page).to have_content('Score de conformité')
      
      # Permit cards
      permits.each do |permit|
        expect(page).to have_content(permit.title)
        expect(page).to have_css(".permit-status-#{permit.status}")
      end
    end

    it 'shows upcoming deadlines and alerts' do
      # Create permit with upcoming deadline
      expiring_permit = create(:immo_promo_permit,
        project: project,
        status: 'approved',
        validity_end_date: 2.weeks.from_now,
        title: 'Permis de construire'
      )
      
      visit immo_promo_engine.project_permit_workflow_dashboard_path(project)
      
      within('.deadline-alerts') do
        expect(page).to have_content('Échéances à venir')
        expect(page).to have_content(expiring_permit.title)
        expect(page).to have_content('Expire dans 14 jours')
        
        click_link 'Renouveler'
      end
      
      expect(page).to have_current_path(
        immo_promo_engine.extend_project_permit_workflow_permit_path(project, expiring_permit)
      )
    end
  end

  describe 'Guided workflow process' do
    it 'provides step-by-step guidance for permit application' do
      visit immo_promo_engine.project_permit_workflow_guide_path(project)
      
      expect(page).to have_content('Guide du workflow')
      expect(page).to have_content('Projet résidentiel')
      
      # Check workflow steps
      expect(page).to have_content('1. Études préliminaires')
      expect(page).to have_content('2. Permis de démolir')
      expect(page).to have_content('3. Permis de construire')
      expect(page).to have_content('4. Autorisations spécifiques')
      
      # Navigate through steps
      within('.workflow-step', text: 'Permis de construire') do
        expect(page).to have_css('.step-pending')
        click_button 'Commencer'
      end
      
      # Step details
      expect(page).to have_content('Documents requis')
      expect(page).to have_content('Délai estimé: 2-3 mois')
      expect(page).to have_content('Coût approximatif')
      
      # Start permit creation
      click_button 'Créer le permis'
      
      expect(page).to have_field('permit_title', with: 'Permis de construire')
    end

    it 'adapts workflow based on project type' do
      project.update(project_type: 'commercial', total_area_sqm: 10000)
      
      visit immo_promo_engine.project_permit_workflow_guide_path(project)
      
      # Additional steps for commercial project
      expect(page).to have_content('Étude d\'impact environnemental')
      expect(page).to have_content('Autorisation d\'exploitation commerciale')
      expect(page).to have_content('Conformité accessibilité PMR')
    end
  end

  describe 'Compliance checklist' do
    let!(:permit) { create(:immo_promo_permit, project: project, status: 'approved') }
    let!(:conditions) do
      [
        create(:immo_promo_permit_condition, permit: permit, description: 'Étude de sol', status: 'completed'),
        create(:immo_promo_permit_condition, permit: permit, description: 'Plan de sécurité', status: 'pending'),
        create(:immo_promo_permit_condition, permit: permit, description: 'Validation architecte', status: 'pending', deadline: 1.week.from_now)
      ]
    end

    it 'tracks compliance requirements' do
      visit immo_promo_engine.project_permit_workflow_compliance_checklist_path(project)
      
      expect(page).to have_content('Checklist de conformité')
      
      # Categories
      within('.checklist-category', text: 'Administratif') do
        expect(page).to have_css('.checklist-item')
      end
      
      within('.checklist-category', text: 'Technique') do
        expect(page).to have_css('.checklist-item')
      end
      
      # Permit conditions
      within("#permit-#{permit.id}-conditions") do
        conditions.each do |condition|
          expect(page).to have_content(condition.description)
        end
        
        # Mark condition as completed
        within("#condition-#{conditions[1].id}") do
          check 'completed'
          fill_in 'evidence', with: 'Document déposé ref: SEC-2024-001'
          click_button 'Valider'
        end
      end
      
      expect(page).to have_content('Condition validée')
      expect(page).to have_content('67%') # Completion percentage
    end

    it 'alerts on overdue conditions' do
      overdue_condition = create(:immo_promo_permit_condition,
        permit: permit,
        description: 'Inspection urgente',
        deadline: 1.day.ago,
        status: 'pending'
      )
      
      visit immo_promo_engine.project_permit_workflow_compliance_checklist_path(project)
      
      within('.overdue-alerts') do
        expect(page).to have_content('Conditions en retard')
        expect(page).to have_content(overdue_condition.description)
        expect(page).to have_css('.alert-danger')
      end
    end
  end

  describe 'Timeline tracking' do
    let!(:permits) { create_list(:immo_promo_permit, 4, project: project) }

    it 'displays permit timeline with milestones' do
      visit immo_promo_engine.project_permit_workflow_timeline_tracker_path(project)
      
      expect(page).to have_content('Timeline des permis')
      expect(page).to have_css('.timeline-visualization')
      
      # Timeline events
      permits.each do |permit|
        expect(page).to have_css(".timeline-event[data-permit-id='#{permit.id}']")
      end
      
      # Filter by permit type
      select 'Permis de construire', from: 'permit_type_filter'
      click_button 'Filtrer'
      
      expect(page).to have_css('.timeline-event', count: 1)
    end

    it 'identifies delays and bottlenecks' do
      delayed_permit = create(:immo_promo_permit,
        project: project,
        status: 'submitted',
        submission_date: 2.months.ago,
        expected_response_date: 1.month.ago
      )
      
      visit immo_promo_engine.project_permit_workflow_timeline_tracker_path(project)
      
      within('.delays-section') do
        expect(page).to have_content('Retards identifiés')
        expect(page).to have_content(delayed_permit.title)
        expect(page).to have_content('30 jours de retard')
        
        click_button 'Relancer'
      end
      
      expect(page).to have_content('Relance envoyée')
    end
  end

  describe 'Critical path analysis' do
    it 'shows permit dependencies and critical path' do
      visit immo_promo_engine.project_permit_workflow_critical_path_path(project)
      
      expect(page).to have_content('Analyse du chemin critique')
      
      # Dependency graph
      expect(page).to have_css('.dependency-graph')
      
      within('.critical-permits') do
        expect(page).to have_content('Permis critiques')
        expect(page).to have_css('.permit-critical')
      end
      
      # Impact analysis
      within('.impact-analysis') do
        expect(page).to have_content('Impact sur le planning')
        expect(page).to have_content('jours de retard potentiel')
      end
      
      # Recommendations
      expect(page).to have_content('Recommandations')
      expect(page).to have_content('Prioriser')
    end
  end

  describe 'Permit submission process' do
    let(:permit) { create(:immo_promo_permit, project: project, status: 'draft') }

    it 'guides through submission preparation' do
      visit immo_promo_engine.project_permit_path(project, permit)
      
      click_button 'Préparer la soumission'
      
      # Document checklist
      within('.submission-checklist') do
        expect(page).to have_content('Documents requis')
        
        # Upload documents
        attach_file 'plans', Rails.root.join('spec/fixtures/files/plan.pdf')
        attach_file 'forms', Rails.root.join('spec/fixtures/files/form.pdf')
        
        check 'Tous les documents sont complets'
      end
      
      # Validate submission
      click_button 'Valider le dossier'
      
      expect(page).to have_content('Dossier complet')
      expect(page).to have_button('Soumettre')
      
      # Submit permit
      within('.submission-form') do
        select 'Électronique', from: 'submission_method'
        fill_in 'tracking_number', with: 'TRACK-2024-001'
        
        click_button 'Soumettre'
      end
      
      expect(page).to have_content('Permis soumis avec succès')
      expect(permit.reload.status).to eq('submitted')
    end

    it 'generates submission package' do
      visit immo_promo_engine.generate_project_permit_workflow_submission_package_path(
        project, permit, format: :pdf
      )
      
      # Check PDF generation
      expect(page.response_headers['Content-Type']).to include('application/pdf')
      expect(page.response_headers['Content-Disposition']).to include('dossier_soumission')
    end
  end

  describe 'Administrative integration' do
    let(:permit) { create(:immo_promo_permit, project: project, status: 'submitted') }

    it 'tracks permit responses' do
      visit immo_promo_engine.project_permit_path(project, permit)
      
      click_button 'Enregistrer réponse'
      
      within('#response-modal') do
        select 'Approuvé avec conditions', from: 'response_status'
        fill_in 'response_date', with: Date.current
        fill_in 'validity_months', with: '24'
        
        # Add conditions
        click_button 'Ajouter condition'
        fill_in 'condition_1', with: 'Respect des normes acoustiques'
        
        click_button 'Ajouter condition'
        fill_in 'condition_2', with: 'Validation finale architecte'
        
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Réponse enregistrée')
      expect(permit.reload.status).to eq('approved_with_conditions')
      expect(permit.permit_conditions.count).to eq(2)
    end

    it 'sends follow-up alerts to administration' do
      visit immo_promo_engine.project_permit_workflow_dashboard_path(project)
      
      within("#permit-#{permit.id}") do
        click_button 'Relancer'
      end
      
      within('#alert-modal') do
        select 'Relance standard', from: 'alert_template'
        fill_in 'additional_message', with: 'Urgent - Début des travaux prévu le mois prochain'
        
        click_button 'Envoyer relance'
      end
      
      expect(page).to have_content('Relance envoyée à l\'administration')
    end
  end

  describe 'Reporting and export' do
    let!(:permits) { create_list(:immo_promo_permit, 5, project: project) }

    it 'generates compliance report' do
      visit immo_promo_engine.project_permit_workflow_dashboard_path(project)
      
      click_link 'Rapport de conformité'
      
      within('#report-options') do
        check 'include_timeline'
        check 'include_compliance'
        check 'include_recommendations'
        
        select 'PDF', from: 'format'
        
        click_button 'Générer rapport'
      end
      
      expect(page.response_headers['Content-Type']).to include('application/pdf')
    end

    it 'exports permit data' do
      visit immo_promo_engine.project_permit_workflow_dashboard_path(project)
      
      click_link 'Exporter données'
      
      select 'Excel', from: 'export_format'
      click_button 'Exporter'
      
      expect(page.response_headers['Content-Type']).to include('spreadsheetml')
    end
  end

  describe 'Mobile experience' do
    it 'provides mobile-friendly permit management' do
      page.driver.browser.manage.window.resize_to(375, 667)
      
      visit immo_promo_engine.project_permit_workflow_dashboard_path(project)
      
      expect(page).to have_css('.mobile-optimized')
      
      # Swipe through permits
      find('.permit-card-mobile', match: :first).swipe_left
      expect(page).to have_css('.permit-actions-mobile')
      
      # Quick actions
      within('.permit-actions-mobile') do
        click_button 'Actions rapides'
      end
      
      expect(page).to have_content('Mettre à jour statut')
      expect(page).to have_content('Ajouter document')
      expect(page).to have_content('Envoyer rappel')
    end
  end
end