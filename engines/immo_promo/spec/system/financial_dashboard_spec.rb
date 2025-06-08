require 'rails_helper'

RSpec.describe 'Financial Dashboard', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, password: 'password123') }
  let(:project) { 
    create(:immo_promo_project, 
      organization: organization, 
      project_manager: user,
      total_budget_cents: 10_000_000_00 # 10M EUR
    ) 
  }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
    
    # Create budget structure
    @budget = create(:immo_promo_budget, project: project, version: 'current')
    @budget_lines = [
      create(:immo_promo_budget_line, 
        budget: @budget, 
        category: 'land',
        planned_amount_cents: 2_000_000_00,
        actual_amount_cents: 2_100_000_00
      ),
      create(:immo_promo_budget_line,
        budget: @budget,
        category: 'construction', 
        planned_amount_cents: 6_000_000_00,
        actual_amount_cents: 5_800_000_00
      ),
      create(:immo_promo_budget_line,
        budget: @budget,
        category: 'fees',
        planned_amount_cents: 1_000_000_00,
        actual_amount_cents: 1_050_000_00
      ),
      create(:immo_promo_budget_line,
        budget: @budget,
        category: 'contingency',
        planned_amount_cents: 1_000_000_00,
        actual_amount_cents: 200_000_00
      )
    ]
  end

  describe 'Financial overview dashboard' do
    it 'displays comprehensive financial metrics' do
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      expect(page).to have_content('Dashboard Financier')
      expect(page).to have_content(project.name)
      
      # Budget overview
      within('.budget-overview') do
        expect(page).to have_content('Budget total: 10 000 000 €')
        expect(page).to have_content('Engagé: 9 150 000 €')
        expect(page).to have_content('Disponible: 850 000 €')
      end
      
      # Budget health indicator
      within('.budget-health') do
        expect(page).to have_css('.status-healthy')
        expect(page).to have_content('Budget maîtrisé')
      end
      
      # Cost trends chart
      expect(page).to have_css('.cost-trends-chart')
      
      # Recent transactions
      within('.recent-transactions') do
        expect(page).to have_content('Transactions récentes')
        expect(page).to have_css('.transaction-item')
      end
    end

    it 'shows budget consumption gauge' do
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      within('.budget-consumption') do
        expect(page).to have_css('.gauge-chart')
        expect(page).to have_content('91.5%') # Consumption percentage
        expect(page).to have_content('du budget engagé')
      end
    end
  end

  describe 'Variance analysis' do
    it 'displays detailed variance by category' do
      visit immo_promo_engine.project_financial_variance_analysis_path(project)
      
      expect(page).to have_content('Analyse des écarts')
      
      # Variance table
      within('.variance-table') do
        # Land: +5% variance
        within('tr', text: 'Foncier') do
          expect(page).to have_content('2 000 000 €') # Planned
          expect(page).to have_content('2 100 000 €') # Actual
          expect(page).to have_content('+100 000 €') # Variance
          expect(page).to have_content('+5.0%')
          expect(page).to have_css('.variance-negative') # Over budget
        end
        
        # Construction: -3.33% variance
        within('tr', text: 'Construction') do
          expect(page).to have_content('6 000 000 €')
          expect(page).to have_content('5 800 000 €')
          expect(page).to have_content('-200 000 €')
          expect(page).to have_content('-3.3%')
          expect(page).to have_css('.variance-positive') # Under budget
        end
      end
      
      # Top variances
      within('.top-variances') do
        expect(page).to have_content('Écarts significatifs')
        expect(page).to have_content('Construction: -200 000 €')
      end
    end

    it 'provides variance explanations and actions' do
      visit immo_promo_engine.project_financial_variance_analysis_path(project)
      
      within('tr', text: 'Foncier') do
        click_button 'Détails'
      end
      
      within('#variance-modal') do
        expect(page).to have_content('Analyse de l\'écart - Foncier')
        
        fill_in 'explanation', with: 'Coûts de dépollution supplémentaires non prévus'
        select 'Externe - Réglementation', from: 'cause'
        
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Explication enregistrée')
    end
  end

  describe 'Cost control' do
    it 'displays cost control measures and projections' do
      visit immo_promo_engine.project_financial_cost_control_path(project)
      
      expect(page).to have_content('Contrôle des coûts')
      
      # Cost drivers
      within('.cost-drivers') do
        expect(page).to have_content('Facteurs de coûts')
        expect(page).to have_content('Main d\'œuvre')
        expect(page).to have_content('Matériaux')
        expect(page).to have_content('Équipements')
      end
      
      # Burn rate
      within('.burn-rate') do
        expect(page).to have_content('Taux de consommation')
        expect(page).to have_content('Quotidien:')
        expect(page).to have_content('Mensuel:')
      end
      
      # Cost projections
      within('.cost-projections') do
        expect(page).to have_content('Projection à terminaison')
        expect(page).to have_content('Écart prévu:')
      end
    end

    it 'identifies savings opportunities' do
      visit immo_promo_engine.project_financial_cost_control_path(project)
      
      within('.savings-opportunities') do
        expect(page).to have_content('Opportunités d\'économies')
        expect(page).to have_css('.savings-item')
        
        # Implement savings
        within('.savings-item', match: :first) do
          expect(page).to have_content('Économie potentielle:')
          click_button 'Appliquer'
        end
      end
      
      expect(page).to have_content('Mesure d\'économie appliquée')
    end
  end

  describe 'Cash flow management' do
    it 'displays cash flow forecast and analysis' do
      visit immo_promo_engine.project_financial_cash_flow_management_path(project)
      
      expect(page).to have_content('Gestion de trésorerie')
      
      # Cash flow chart
      expect(page).to have_css('.cash-flow-chart')
      
      # Monthly breakdown
      within('.cash-flow-table') do
        expect(page).to have_content('Mois')
        expect(page).to have_content('Entrées')
        expect(page).to have_content('Sorties')
        expect(page).to have_content('Solde')
        expect(page).to have_content('Cumulé')
      end
      
      # Funding gaps
      within('.funding-gaps') do
        expect(page).to have_content('Besoins de financement')
        expect(page).to have_css('.gap-alert')
      end
    end

    it 'allows cash flow scenario planning' do
      visit immo_promo_engine.project_financial_cash_flow_management_path(project)
      
      click_button 'Scénarios'
      
      within('#scenario-modal') do
        # Adjust parameters
        fill_in 'sales_delay', with: '2'
        fill_in 'payment_terms', with: '60'
        check 'include_weather_delays'
        
        click_button 'Calculer'
      end
      
      # Updated forecast
      expect(page).to have_content('Scénario mis à jour')
      within('.scenario-results') do
        expect(page).to have_content('Pic de trésorerie:')
        expect(page).to have_content('Financement additionnel requis:')
      end
    end
  end

  describe 'Budget scenarios' do
    it 'generates multiple budget scenarios' do
      visit immo_promo_engine.project_financial_budget_scenarios_path(project)
      
      expect(page).to have_content('Scénarios budgétaires')
      
      # Scenario comparison
      within('.scenario-comparison') do
        # Optimistic
        within('.scenario-optimistic') do
          expect(page).to have_content('Optimiste')
          expect(page).to have_content('-5%')
          expect(page).to have_css('.scenario-positive')
        end
        
        # Realistic
        within('.scenario-realistic') do
          expect(page).to have_content('Réaliste')
          expect(page).to have_content('Base')
        end
        
        # Pessimistic
        within('.scenario-pessimistic') do
          expect(page).to have_content('Pessimiste')
          expect(page).to have_content('+10%')
          expect(page).to have_css('.scenario-negative')
        end
      end
      
      # Stress test
      within('.stress-test') do
        expect(page).to have_content('Test de stress')
        expect(page).to have_content('Impact total:')
        expect(page).to have_content('Mitigation requise:')
      end
    end

    it 'performs sensitivity analysis' do
      visit immo_promo_engine.project_financial_budget_scenarios_path(project)
      
      click_button 'Analyse de sensibilité'
      
      within('.sensitivity-analysis') do
        # Adjust parameters
        find('#construction-cost-slider').set(110) # +10%
        find('#interest-rate-slider').set(4.5) # 4.5%
        find('#sales-price-slider').set(95) # -5%
        
        click_button 'Recalculer'
      end
      
      # Impact results
      within('.sensitivity-results') do
        expect(page).to have_content('Impact sur la rentabilité')
        expect(page).to have_content('TRI ajusté:')
        expect(page).to have_content('Marge nette:')
      end
    end
  end

  describe 'Profitability analysis' do
    it 'calculates and displays profitability metrics' do
      visit immo_promo_engine.project_financial_profitability_analysis_path(project)
      
      expect(page).to have_content('Analyse de rentabilité')
      
      within('.profitability-metrics') do
        expect(page).to have_content('Marge brute:')
        expect(page).to have_content('Marge nette:')
        expect(page).to have_content('ROI:')
        expect(page).to have_content('TRI:')
        expect(page).to have_content('Délai de récupération:')
      end
      
      # Margin breakdown
      within('.margin-analysis') do
        expect(page).to have_content('Analyse des marges')
        expect(page).to have_css('.margin-chart')
        
        # By lot type
        expect(page).to have_content('Par type de lot')
        expect(page).to have_content('T2:')
        expect(page).to have_content('T3:')
        expect(page).to have_content('T4:')
      end
    end
  end

  describe 'Budget adjustments' do
    it 'allows budget reallocation between categories' do
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      click_button 'Réallocation budgétaire'
      
      within('#reallocation-modal') do
        select 'Contingence', from: 'source_category'
        select 'Construction', from: 'target_category'
        fill_in 'amount', with: '200000'
        fill_in 'justification', with: 'Coûts supplémentaires structure béton'
        
        click_button 'Réallouer'
      end
      
      expect(page).to have_content('Réallocation effectuée')
      
      # Check updated values
      visit immo_promo_engine.project_financial_variance_analysis_path(project)
      
      within('tr', text: 'Contingence') do
        expect(page).to have_content('800 000 €') # 1M - 200K
      end
      
      within('tr', text: 'Construction') do
        expect(page).to have_content('6 200 000 €') # 6M + 200K
      end
    end

    it 'requires approval for large adjustments' do
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      click_button 'Ajustement budgétaire'
      
      within('#adjustment-modal') do
        select 'Construction', from: 'category'
        fill_in 'amount', with: '2000000' # 20% of total budget
        fill_in 'reason', with: 'Modification majeure du programme'
        
        click_button 'Soumettre'
      end
      
      expect(page).to have_content('Approbation requise')
      expect(page).to have_content('Cet ajustement dépasse les limites d\'approbation')
      
      # Approval workflow
      within('.approval-required') do
        expect(page).to have_content('Niveau d\'approbation: Direction')
        click_button 'Demander approbation'
      end
      
      expect(page).to have_content('Demande d\'approbation envoyée')
    end
  end

  describe 'Financial alerts' do
    it 'configures budget alerts' do
      visit immo_promo_engine.project_financial_cost_control_path(project)
      
      click_button 'Configurer alertes'
      
      within('#alerts-modal') do
        # Budget overrun alert
        within('.alert-config', text: 'Dépassement budgétaire') do
          fill_in 'threshold', with: '95'
          check 'enabled'
          fill_in 'recipients', with: 'cfo@example.com, pm@example.com'
        end
        
        # Burn rate alert
        within('.alert-config', text: 'Taux de consommation') do
          fill_in 'threshold', with: '120' # 120% of planned
          check 'enabled'
          select 'Hebdomadaire', from: 'frequency'
        end
        
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Alertes configurées')
    end
  end

  describe 'Financial reporting' do
    it 'generates comprehensive financial report' do
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      click_link 'Générer rapport financier'
      
      within('#report-options') do
        check 'include_overview'
        check 'include_variance'
        check 'include_cash_flow'
        check 'include_profitability'
        
        select 'Direction', from: 'report_level'
        select 'PDF', from: 'format'
        
        click_button 'Générer'
      end
      
      # Check PDF generation
      expect(page.response_headers['Content-Type']).to include('application/pdf')
      expect(page.response_headers['Content-Disposition']).to include('rapport_financier')
    end

    it 'exports budget data for analysis' do
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      click_link 'Exporter données'
      
      within('#export-options') do
        check 'budget_lines'
        check 'transactions'
        check 'projections'
        
        select 'Excel', from: 'format'
        
        click_button 'Exporter'
      end
      
      expect(page.response_headers['Content-Type']).to include('spreadsheetml')
    end
  end

  describe 'Accounting system integration' do
    it 'synchronizes with external accounting system' do
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      click_button 'Synchroniser comptabilité'
      
      within('#sync-modal') do
        select 'SAP', from: 'accounting_system'
        check 'sync_actuals'
        check 'sync_commitments'
        fill_in 'cost_center', with: 'CC-PROJ-001'
        
        click_button 'Synchroniser'
      end
      
      expect(page).to have_content('Synchronisation en cours')
      
      # Progress indicator
      expect(page).to have_css('.sync-progress')
      
      # Completion
      expect(page).to have_content('Synchronisation terminée', wait: 10)
      expect(page).to have_content('Données mises à jour')
    end
  end

  describe 'Mobile financial management' do
    it 'provides mobile-optimized financial views' do
      page.driver.browser.manage.window.resize_to(375, 667)
      
      visit immo_promo_engine.project_financial_dashboard_path(project)
      
      expect(page).to have_css('.mobile-dashboard')
      
      # Swipeable metric cards
      find('.metric-card', match: :first).swipe_left
      expect(page).to have_css('.metric-details')
      
      # Expandable sections
      find('.section-header', text: 'Écarts budgétaires').click
      expect(page).to have_css('.variance-summary-mobile')
      
      # Quick actions
      find('.mobile-fab').click
      expect(page).to have_content('Actions rapides')
      expect(page).to have_link('Voir écarts')
      expect(page).to have_link('Rapport flash')
    end
  end
end