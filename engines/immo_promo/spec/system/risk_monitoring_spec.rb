require 'rails_helper'

RSpec.describe 'Risk Monitoring', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, password: 'password123') }
  let(:project) { 
    create(:immo_promo_project, 
      organization: organization, 
      project_manager: user
    ) 
  }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
    
    # Create risk structure
    @risks = [
      create(:immo_promo_risk, 
        project: project,
        title: 'Retard livraison matériaux',
        category: 'schedule',
        severity: 'critical',
        probability: 'high',
        impact: 'major',
        status: 'active'
      ),
      create(:immo_promo_risk,
        project: project,
        title: 'Dépassement budget fondations',
        category: 'financial',
        severity: 'high',
        probability: 'medium',
        impact: 'major',
        status: 'active'
      ),
      create(:immo_promo_risk,
        project: project,
        title: 'Non-conformité environnementale',
        category: 'regulatory',
        severity: 'medium',
        probability: 'low',
        impact: 'moderate',
        status: 'active'
      ),
      create(:immo_promo_risk,
        project: project,
        title: 'Défaillance sous-traitant',
        category: 'contractual',
        severity: 'low',
        probability: 'low',
        impact: 'minor',
        status: 'mitigated'
      )
    ]
    
    # Create mitigation actions
    @mitigation_actions = [
      create(:immo_promo_mitigation_action,
        risk: @risks[0],
        action_type: 'preventive',
        description: 'Diversifier les fournisseurs',
        status: 'in_progress'
      ),
      create(:immo_promo_mitigation_action,
        risk: @risks[1],
        action_type: 'corrective',
        description: 'Renégocier contrats',
        status: 'planned'
      )
    ]
  end

  describe 'Risk monitoring dashboard' do
    it 'displays comprehensive risk overview' do
      visit immo_promo_engine.project_risk_monitoring_dashboard_path(project)
      
      expect(page).to have_content('Monitoring des Risques')
      expect(page).to have_content(project.name)
      
      # Overall risk level
      within('.overall-risk-level') do
        expect(page).to have_css('.risk-critical')
        expect(page).to have_content('Niveau de risque: Critique')
      end
      
      # Risk metrics
      within('.risk-metrics') do
        expect(page).to have_content('Risques critiques: 1')
        expect(page).to have_content('Risques élevés: 1')
        expect(page).to have_content('Actions en retard: 0')
        expect(page).to have_content('Atténuation: 25%')
      end
      
      # Active alerts
      within('.risk-alerts') do
        expect(page).to have_content('1 risques critiques actifs')
        expect(page).to have_content('Action immédiate requise')
      end
    end

    it 'displays interactive risk matrix' do
      visit immo_promo_engine.project_risk_monitoring_dashboard_path(project)
      
      within('.risk-matrix') do
        expect(page).to have_content('Matrice des Risques')
        expect(page).to have_css('.matrix-grid')
        
        # Matrix cells
        expect(page).to have_css('.matrix-cell', minimum: 25) # 5x5 grid
        
        # Risk count in cells
        cell = find('.matrix-cell[data-probability="high"][data-impact="major"]')
        expect(cell).to have_content('1')
        
        # Click cell to filter
        cell.click
      end
      
      # Filtered view
      expect(page).to have_content('Filtre: Probabilité élevée, Impact majeur')
      expect(page).to have_content(@risks[0].title)
    end

    it 'shows mitigation tracking progress' do
      visit immo_promo_engine.project_risk_monitoring_dashboard_path(project)
      
      within('.mitigation-tracking') do
        expect(page).to have_content('État des Atténuations')
        expect(page).to have_css('.mitigation-progress-chart')
        
        expect(page).to have_content('Actions complétées: 0')
        expect(page).to have_content('En cours: 1')
        expect(page).to have_content('En retard: 0')
        
        click_link 'Voir toutes les actions'
      end
      
      expect(page).to have_current_path(
        immo_promo_engine.project_risk_monitoring_risk_register_path(project)
      )
    end
  end

  describe 'Risk register management' do
    it 'displays and filters risk register' do
      visit immo_promo_engine.project_risk_monitoring_risk_register_path(project)
      
      expect(page).to have_content('Registre des Risques')
      expect(page).to have_css('.risk-item', count: 4)
      
      # Filter by category
      within('.filters-panel') do
        select 'Financier', from: 'category_filter'
        click_button 'Filtrer'
      end
      
      expect(page).to have_css('.risk-item', count: 1)
      expect(page).to have_content(@risks[1].title)
      
      # Filter by severity
      within('.filters-panel') do
        click_button 'Réinitialiser'
        select 'Critique', from: 'severity_filter'
        click_button 'Filtrer'
      end
      
      expect(page).to have_css('.risk-item', count: 1)
      expect(page).to have_content(@risks[0].title)
    end

    it 'allows creating new risks' do
      visit immo_promo_engine.project_risk_monitoring_dashboard_path(project)
      
      click_button 'Nouveau risque'
      
      within('#new-risk-modal') do
        fill_in 'title', with: 'Pénurie main d\'œuvre qualifiée'
        fill_in 'description', with: 'Difficulté à recruter des ouvriers spécialisés'
        select 'Organisationnel', from: 'category'
        select 'Élevée', from: 'probability'
        select 'Majeur', from: 'impact'
        select stakeholder.name, from: 'risk_owner_id'
        
        click_button 'Enregistrer le risque'
      end
      
      expect(page).to have_content('Risque identifié et enregistré')
      expect(page).to have_content('Pénurie main d\'œuvre qualifiée')
    end

    it 'enables risk assessment updates' do
      visit immo_promo_engine.project_risk_monitoring_risk_register_path(project)
      
      within("#risk-#{@risks[2].id}") do
        click_button 'Réévaluer'
      end
      
      within('#assessment-modal') do
        select 'Moyenne', from: 'probability'
        select 'Majeur', from: 'impact'
        fill_in 'notes', with: 'Nouvelles réglementations annoncées'
        fill_in 'reassessment_reason', with: 'Évolution du contexte réglementaire'
        
        click_button 'Mettre à jour'
      end
      
      expect(page).to have_content('Évaluation du risque mise à jour')
      
      # Check severity update
      within("#risk-#{@risks[2].id}") do
        expect(page).to have_css('.severity-high')
      end
    end
  end

  describe 'Mitigation action management' do
    it 'creates and tracks mitigation actions' do
      visit immo_promo_engine.project_risk_monitoring_risk_register_path(project)
      
      within("#risk-#{@risks[2].id}") do
        click_button 'Plan d\'atténuation'
      end
      
      within('#mitigation-modal') do
        select 'Préventive', from: 'action_type'
        fill_in 'description', with: 'Audit environnemental mensuel'
        select stakeholder.name, from: 'responsible_id'
        fill_in 'due_date', with: 1.month.from_now
        fill_in 'cost_estimate', with: '5000'
        fill_in 'effectiveness_estimate', with: '80'
        
        click_button 'Créer action'
      end
      
      expect(page).to have_content('Action d\'atténuation créée')
      
      within("#risk-#{@risks[2].id}") do
        expect(page).to have_css('.mitigation-in-progress')
        expect(page).to have_content('1 action en cours')
      end
    end

    it 'updates mitigation action status' do
      visit immo_promo_engine.project_risk_monitoring_risk_register_path(project)
      
      within("#risk-#{@risks[0].id}") do
        click_link 'Voir actions'
      end
      
      within("#action-#{@mitigation_actions[0].id}") do
        click_button 'Marquer complété'
      end
      
      within('#completion-modal') do
        fill_in 'completion_notes', with: '3 nouveaux fournisseurs identifiés et validés'
        fill_in 'actual_cost', with: '3500'
        select '90', from: 'effectiveness_achieved'
        
        click_button 'Confirmer'
      end
      
      expect(page).to have_content('Action complétée')
      expect(@mitigation_actions[0].reload.status).to eq('completed')
    end
  end

  describe 'Alert center' do
    it 'displays and manages risk alerts' do
      visit immo_promo_engine.project_risk_monitoring_alert_center_path(project)
      
      expect(page).to have_content('Centre d\'alertes')
      
      # Active alerts
      within('.active-alerts') do
        expect(page).to have_css('.alert-item')
        expect(page).to have_content('Risque critique actif')
      end
      
      # Alert configurations
      within('.alert-configurations') do
        expect(page).to have_content('Configurations d\'alertes')
        expect(page).to have_css('.config-item')
      end
      
      # Configure new alert
      click_button 'Nouvelle alerte'
      
      within('#alert-config-modal') do
        select 'Nouveau risque critique', from: 'alert_type'
        fill_in 'threshold_value', with: '1'
        select 'Supérieur à', from: 'comparison_operator'
        check 'email'
        check 'sms'
        fill_in 'recipients', with: 'pm@example.com, risk@example.com'
        
        click_button 'Configurer'
      end
      
      expect(page).to have_content('Configuration d\'alerte enregistrée')
    end

    it 'acknowledges and manages alerts' do
      # Create an active alert
      alert = create(:alert, project: project, alert_type: 'risk_escalation')
      
      visit immo_promo_engine.project_risk_monitoring_alert_center_path(project)
      
      within("#alert-#{alert.id}") do
        expect(page).to have_css('.alert-unacknowledged')
        click_button 'Acquitter'
      end
      
      expect(page).to have_content('Alerte acquittée')
      within("#alert-#{alert.id}") do
        expect(page).to have_css('.alert-acknowledged')
      end
    end
  end

  describe 'Early warning system' do
    it 'displays predictive risk indicators' do
      visit immo_promo_engine.project_risk_monitoring_early_warning_system_path(project)
      
      expect(page).to have_content('Système d\'alerte précoce')
      
      # Warning indicators
      within('.warning-indicators') do
        expect(page).to have_css('.indicator-item')
        expect(page).to have_content('Indicateurs de risque')
      end
      
      # Trend analysis
      within('.trend-analysis') do
        expect(page).to have_content('Analyse des tendances')
        expect(page).to have_css('.trend-chart')
      end
      
      # Predictive alerts
      within('.predictive-alerts') do
        expect(page).to have_content('Alertes prédictives')
        expect(page).to have_content('Risque de retard projet')
        expect(page).to have_content('Probabilité: 65%')
      end
    end

    it 'configures threshold violations' do
      visit immo_promo_engine.project_risk_monitoring_early_warning_system_path(project)
      
      click_button 'Configurer seuils'
      
      within('#threshold-modal') do
        # Budget threshold
        within('.threshold-config', text: 'Dépassement budget') do
          fill_in 'threshold', with: '5'
          select 'Pourcentage', from: 'unit'
        end
        
        # Schedule threshold
        within('.threshold-config', text: 'Retard planning') do
          fill_in 'threshold', with: '7'
          select 'Jours', from: 'unit'
        end
        
        click_button 'Enregistrer seuils'
      end
      
      expect(page).to have_content('Seuils configurés')
    end
  end

  describe 'Risk reporting' do
    it 'generates comprehensive risk report' do
      visit immo_promo_engine.project_risk_monitoring_dashboard_path(project)
      
      click_link 'Rapport des risques'
      
      within('#report-options') do
        check 'include_matrix'
        check 'include_register'
        check 'include_mitigation'
        check 'include_trends'
        check 'include_recommendations'
        
        select 'Direction', from: 'report_level'
        select 'PDF', from: 'format'
        
        click_button 'Générer'
      end
      
      expect(page.response_headers['Content-Type']).to include('application/pdf')
      expect(page.response_headers['Content-Disposition']).to include('rapport_risques')
    end

    it 'exports risk matrix visualization' do
      visit immo_promo_engine.project_risk_monitoring_dashboard_path(project)
      
      within('.risk-matrix') do
        click_link 'Exporter matrice'
      end
      
      select 'SVG', from: 'export_format'
      click_button 'Exporter'
      
      expect(page.response_headers['Content-Type']).to include('image/svg+xml')
    end
  end

  describe 'Risk escalation workflow' do
    it 'handles automatic risk escalation' do
      # Update risk to trigger escalation
      low_risk = @risks[3]
      low_risk.update(probability: 'very_high', impact: 'catastrophic')
      
      visit immo_promo_engine.project_risk_monitoring_risk_register_path(project)
      
      within("#risk-#{low_risk.id}") do
        expect(page).to have_css('.escalation-indicator')
        expect(page).to have_content('Escaladé')
        expect(page).to have_css('.severity-critical')
      end
      
      # Check escalation notification
      within('.notifications') do
        expect(page).to have_content('Escalade risque')
        expect(page).to have_content(low_risk.title)
      end
    end

    it 'manages manual risk escalation' do
      visit immo_promo_engine.project_risk_monitoring_risk_register_path(project)
      
      within("#risk-#{@risks[2].id}") do
        click_button 'Escalader'
      end
      
      within('#escalation-modal') do
        select 'Direction', from: 'escalation_level'
        fill_in 'reason', with: 'Impact potentiel sous-estimé'
        check 'notify_sponsor'
        check 'notify_committee'
        
        click_button 'Confirmer escalade'
      end
      
      expect(page).to have_content('Risque escaladé')
      expect(page).to have_content('Notification envoyée à la direction')
    end
  end

  describe 'Mobile risk management' do
    it 'provides mobile-optimized risk monitoring' do
      page.driver.browser.manage.window.resize_to(375, 667)
      
      visit immo_promo_engine.project_risk_monitoring_dashboard_path(project)
      
      expect(page).to have_css('.mobile-risk-dashboard')
      
      # Swipeable risk cards
      find('.risk-card-mobile', match: :first).swipe_left
      expect(page).to have_css('.risk-actions-mobile')
      
      # Quick risk assessment
      find('.mobile-fab').click
      expect(page).to have_link('Évaluation rapide')
      
      click_link 'Évaluation rapide'
      
      within('.mobile-assessment-form') do
        select @risks[0].title, from: 'risk'
        # Slider controls for probability/impact
        expect(page).to have_css('.probability-slider')
        expect(page).to have_css('.impact-slider')
        
        click_button 'Enregistrer'
      end
    end
  end

  describe 'Risk collaboration features' do
    it 'enables risk discussion and comments' do
      visit immo_promo_engine.project_risk_path(project, @risks[0])
      
      within('.risk-discussion') do
        fill_in 'comment', with: 'Réunion avec fournisseurs prévue demain'
        click_button 'Commenter'
      end
      
      expect(page).to have_content('Réunion avec fournisseurs prévue demain')
      expect(page).to have_content(user.name)
      expect(page).to have_content('il y a moins d\'une minute')
      
      # Tag stakeholders
      fill_in 'comment', with: '@stakeholder1 pouvez-vous confirmer la disponibilité?'
      click_button 'Commenter'
      
      expect(page).to have_css('.mention-tag')
    end

    it 'tracks risk history and changes' do
      visit immo_promo_engine.project_risk_path(project, @risks[0])
      
      click_tab 'Historique'
      
      within('.risk-history') do
        expect(page).to have_content('Historique des modifications')
        expect(page).to have_css('.history-item')
        
        expect(page).to have_content('Risque créé')
        expect(page).to have_content('Évaluation initiale')
      end
    end
  end

  private

  def stakeholder
    @stakeholder ||= create(:immo_promo_stakeholder, project: project)
  end

  def click_tab(tab_name)
    find('.nav-tabs').find('a', text: tab_name).click
  end
end