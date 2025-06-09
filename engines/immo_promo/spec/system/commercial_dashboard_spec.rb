require 'rails_helper'

RSpec.describe 'Commercial Dashboard', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, password: 'password123') }
  let(:project) { 
    create(:immo_promo_project, 
      organization: organization, 
      project_manager: user,
      total_units: 50,
      project_type: 'residential'
    ) 
  }
  
  before do
    driven_by(:selenium_chrome_headless)
    login_as(user, scope: :user)
    
    # Create lots structure
    @lots = [
      create(:immo_promo_lot, project: project, lot_type: 'T2', floor: 0, orientation: 'south', base_price_cents: 250_000_00, status: 'available'),
      create(:immo_promo_lot, project: project, lot_type: 'T3', floor: 1, orientation: 'east', base_price_cents: 350_000_00, status: 'available'),
      create(:immo_promo_lot, project: project, lot_type: 'T3', floor: 2, orientation: 'west', base_price_cents: 360_000_00, status: 'reserved'),
      create(:immo_promo_lot, project: project, lot_type: 'T4', floor: 3, orientation: 'south', base_price_cents: 450_000_00, status: 'reserved'),
      create(:immo_promo_lot, project: project, lot_type: 'T4', floor: 4, orientation: 'south', base_price_cents: 480_000_00, status: 'sold')
    ]
    
    # Create reservations
    @reservations = [
      create(:immo_promo_reservation, lot: @lots[2], client_name: 'Jean Dupont', status: 'active'),
      create(:immo_promo_reservation, lot: @lots[3], client_name: 'Marie Martin', status: 'active'),
      create(:immo_promo_reservation, lot: @lots[4], client_name: 'Pierre Durand', status: 'converted')
    ]
  end

  describe 'Commercial overview dashboard' do
    it 'displays sales metrics and inventory status' do
      visit immo_promo_engine.commercial_dashboard_project_path(project)
      
      expect(page).to have_content('Dashboard Commercial')
      expect(page).to have_content(project.name)
      
      # Inventory overview
      within('.inventory-overview') do
        expect(page).to have_content('Total lots: 5')
        expect(page).to have_content('Disponibles: 2')
        expect(page).to have_content('Réservés: 2')
        expect(page).to have_content('Vendus: 1')
      end
      
      # Revenue metrics
      within('.revenue-metrics') do
        expect(page).to have_content('Chiffre d\'affaires potentiel')
        expect(page).to have_content('1 890 000 €') # Sum of all lots
        expect(page).to have_content('Réalisé: 480 000 €') # Sold lots
      end
      
      # Sales velocity
      within('.sales-velocity') do
        expect(page).to have_content('Vitesse de vente')
        expect(page).to have_content('Taux de conversion')
      end
    end

    it 'shows sales funnel visualization' do
      visit immo_promo_engine.commercial_dashboard_project_path(project)
      
      within('.sales-funnel') do
        expect(page).to have_css('.funnel-stage', count: 5)
        expect(page).to have_content('Prospects')
        expect(page).to have_content('Visites')
        expect(page).to have_content('Réservations')
        expect(page).to have_content('Contrats')
        expect(page).to have_content('Livrés')
      end
    end
  end

  describe 'Lot inventory management' do
    it 'displays interactive lot inventory with filters' do
      visit immo_promo_engine.commercial_dashboard_lot_inventory_project_path(project)
      
      expect(page).to have_content('Inventaire des lots')
      
      # Grid view
      expect(page).to have_css('.lot-grid')
      expect(page).to have_css('.lot-card', count: 5)
      
      # Filter by status
      within('.filters-panel') do
        uncheck 'status_all'
        check 'status_available'
        click_button 'Appliquer'
      end
      
      expect(page).to have_css('.lot-card', count: 2)
      
      # Filter by type
      within('.filters-panel') do
        check 'status_all'
        select 'T3', from: 'lot_type'
        click_button 'Appliquer'
      end
      
      expect(page).to have_css('.lot-card', count: 2)
      
      # Price range filter
      within('.filters-panel') do
        fill_in 'min_price', with: '300000'
        fill_in 'max_price', with: '400000'
        click_button 'Appliquer'
      end
      
      expect(page).to have_css('.lot-card', count: 2)
    end

    it 'provides building view with floor plans' do
      visit immo_promo_engine.commercial_dashboard_lot_inventory_project_path(project)
      
      click_button 'Vue bâtiment'
      
      expect(page).to have_css('.building-view')
      
      # Floor selector
      within('.floor-selector') do
        expect(page).to have_button('RDC')
        expect(page).to have_button('1er')
        expect(page).to have_button('2ème')
      end
      
      # Select floor
      click_button '2ème'
      
      within('.floor-plan') do
        expect(page).to have_css('.lot-unit')
        # Hover lot for details
        find('.lot-unit', match: :first).hover
        expect(page).to have_css('.lot-tooltip')
      end
    end

    it 'allows quick lot status updates' do
      visit immo_promo_engine.commercial_dashboard_lot_inventory_project_path(project)
      
      within("#lot-#{@lots[0].id}") do
        click_button 'Actions'
        click_link 'Réserver'
      end
      
      within('#reservation-modal') do
        fill_in 'client_name', with: 'Sophie Lambert'
        fill_in 'client_email', with: 'sophie@example.com'
        fill_in 'client_phone', with: '0612345678'
        fill_in 'deposit_amount', with: '5000'
        
        click_button 'Créer réservation'
      end
      
      expect(page).to have_content('Réservation créée')
      expect(@lots[0].reload.status).to eq('reserved')
    end
  end

  describe 'Reservation management' do
    it 'displays reservation pipeline and metrics' do
      visit immo_promo_engine.commercial_dashboard_reservation_management_project_path(project)
      
      expect(page).to have_content('Gestion des réservations')
      
      # Pipeline overview
      within('.reservation-pipeline') do
        expect(page).to have_content('Actives: 2')
        expect(page).to have_content('En attente: 0')
        expect(page).to have_content('Expirées: 0')
        expect(page).to have_content('Converties: 1')
      end
      
      # Conversion metrics
      within('.conversion-metrics') do
        expect(page).to have_content('Taux de conversion: 33.3%')
        expect(page).to have_content('Temps moyen conversion:')
        expect(page).to have_content('Taux d\'annulation:')
      end
      
      # Active reservations list
      within('.active-reservations') do
        expect(page).to have_content('Jean Dupont')
        expect(page).to have_content('Marie Martin')
        
        # Check expiry countdown
        expect(page).to have_css('.expiry-countdown')
      end
    end

    it 'handles reservation conversion to sale' do
      visit immo_promo_engine.commercial_dashboard_reservation_management_project_path(project)
      
      within("#reservation-#{@reservations[0].id}") do
        click_button 'Convertir en vente'
      end
      
      within('#sale-conversion-modal') do
        fill_in 'sale_price', with: '360000'
        fill_in 'notary_name', with: 'Me. Leblanc'
        fill_in 'signing_date', with: 1.month.from_now
        attach_file 'contract', Rails.root.join('spec/fixtures/files/contract.pdf')
        
        click_button 'Confirmer la vente'
      end
      
      expect(page).to have_content('Vente confirmée')
      expect(@lots[2].reload.status).to eq('sold')
      expect(@reservations[0].reload.status).to eq('converted')
    end

    it 'manages expiring reservations' do
      # Create expiring reservation
      expiring = create(:immo_promo_reservation, 
        lot: @lots[1], 
        created_at: 25.days.ago,
        expiry_date: 5.days.from_now,
        status: 'active'
      )
      
      visit immo_promo_engine.commercial_dashboard_reservation_management_project_path(project)
      
      within('.expiring-reservations') do
        expect(page).to have_content('Réservations à renouveler')
        expect(page).to have_content(expiring.client_name)
        expect(page).to have_content('Expire dans 5 jours')
        
        click_button 'Prolonger'
      end
      
      within('#extend-reservation-modal') do
        fill_in 'extension_days', with: '30'
        fill_in 'reason', with: 'Client en attente accord bancaire'
        
        click_button 'Prolonger'
      end
      
      expect(page).to have_content('Réservation prolongée')
    end
  end

  describe 'Pricing strategy' do
    it 'displays pricing analysis and recommendations' do
      visit immo_promo_engine.commercial_dashboard_pricing_strategy_project_path(project)
      
      expect(page).to have_content('Stratégie de tarification')
      
      # Pricing by type
      within('.pricing-by-type') do
        expect(page).to have_content('Prix moyen par type')
        expect(page).to have_content('T2: 250 000 €')
        expect(page).to have_content('T3: 355 000 €')
        expect(page).to have_content('T4: 465 000 €')
      end
      
      # Floor premium analysis
      within('.floor-premium') do
        expect(page).to have_content('Prime d\'étage')
        expect(page).to have_css('.premium-chart')
      end
      
      # Market comparison
      within('.market-comparison') do
        expect(page).to have_content('Comparaison marché')
        expect(page).to have_content('Prix moyen secteur:')
        expect(page).to have_content('Positionnement:')
      end
    end

    it 'allows dynamic pricing adjustments' do
      visit immo_promo_engine.commercial_dashboard_pricing_strategy_project_path(project)
      
      click_button 'Ajuster les prix'
      
      within('#pricing-adjustment-modal') do
        # Global adjustment
        choose 'global_adjustment'
        fill_in 'adjustment_percentage', with: '3'
        fill_in 'reason', with: 'Évolution du marché favorable'
        
        # Preview changes
        click_button 'Prévisualiser'
        
        expect(page).to have_content('Impact: +56 700 €')
        
        click_button 'Appliquer'
      end
      
      expect(page).to have_content('Prix mis à jour')
      
      # Verify price updates
      expect(@lots[0].reload.base_price_cents).to eq(257_500_00) # 250k + 3%
    end

    it 'suggests pricing optimizations' do
      visit immo_promo_engine.commercial_dashboard_pricing_strategy_project_path(project)
      
      within('.pricing-suggestions') do
        expect(page).to have_content('Recommandations tarifaires')
        expect(page).to have_css('.suggestion-item')
        
        # Apply suggestion
        within('.suggestion-item', match: :first) do
          expect(page).to have_content('Impact estimé:')
          click_button 'Appliquer'
        end
      end
      
      expect(page).to have_content('Optimisation appliquée')
    end
  end

  describe 'Sales pipeline' do
    it 'visualizes sales pipeline stages' do
      visit immo_promo_engine.commercial_dashboard_sales_pipeline_project_path(project)
      
      expect(page).to have_content('Pipeline commercial')
      
      # Pipeline stages with values
      within('.pipeline-visualization') do
        expect(page).to have_css('.pipeline-stage', count: 5)
        
        within('.stage-prospects') do
          expect(page).to have_content('Prospects')
          expect(page).to have_content('15') # Example count
        end
        
        within('.stage-visits') do
          expect(page).to have_content('Visites')
          expect(page).to have_content('8')
        end
        
        within('.stage-reservations') do
          expect(page).to have_content('Réservations')
          expect(page).to have_content('3')
        end
      end
      
      # Pipeline value
      within('.pipeline-value') do
        expect(page).to have_content('Valeur totale pipeline')
        expect(page).to have_content('Valeur pondérée')
      end
    end

    it 'provides sales forecasting' do
      visit immo_promo_engine.commercial_dashboard_sales_pipeline_project_path(project)
      
      within('.sales-forecast') do
        expect(page).to have_content('Prévisions de vente')
        expect(page).to have_content('Mois prochain:')
        expect(page).to have_content('Trimestre:')
        expect(page).to have_content('Fin d\'année:')
        
        # Confidence levels
        expect(page).to have_css('.confidence-indicator')
      end
      
      # Scenario planning
      click_button 'Scénarios'
      
      within('#forecast-scenarios') do
        expect(page).to have_content('Optimiste')
        expect(page).to have_content('Réaliste')
        expect(page).to have_content('Pessimiste')
      end
    end
  end

  describe 'Customer insights' do
    it 'analyzes customer segments and preferences' do
      visit immo_promo_engine.commercial_dashboard_customer_insights_project_path(project)
      
      expect(page).to have_content('Insights clients')
      
      # Customer segments
      within('.customer-segments') do
        expect(page).to have_content('Segmentation clients')
        expect(page).to have_css('.segment-chart')
        
        expect(page).to have_content('Primo-accédants:')
        expect(page).to have_content('Investisseurs:')
        expect(page).to have_content('Familles:')
      end
      
      # Preferences analysis
      within('.customer-preferences') do
        expect(page).to have_content('Préférences identifiées')
        expect(page).to have_content('Types de lots préférés')
        expect(page).to have_content('Étages préférés')
        expect(page).to have_content('Sensibilité prix')
      end
      
      # Buyer journey
      within('.buyer-journey') do
        expect(page).to have_content('Parcours d\'achat')
        expect(page).to have_css('.journey-timeline')
      end
    end
  end

  describe 'Commercial reporting' do
    it 'generates sales performance report' do
      visit immo_promo_engine.commercial_dashboard_project_path(project)
      
      click_link 'Rapport commercial'
      
      within('#report-options') do
        select 'Mois en cours', from: 'period'
        check 'include_inventory'
        check 'include_pipeline'
        check 'include_forecasts'
        check 'include_insights'
        
        select 'PDF', from: 'format'
        
        click_button 'Générer'
      end
      
      expect(page.response_headers['Content-Type']).to include('application/pdf')
      expect(page.response_headers['Content-Disposition']).to include('rapport_commercial')
    end

    it 'creates commercial offer documents' do
      visit immo_promo_engine.commercial_dashboard_lot_inventory_project_path(project)
      
      within("#lot-#{@lots[0].id}") do
        click_button 'Générer offre'
      end
      
      within('#offer-options') do
        fill_in 'client_name', with: 'M. et Mme Blanc'
        check 'include_floor_plan'
        check 'include_3d_views'
        check 'include_financing'
        
        click_button 'Générer'
      end
      
      expect(page.response_headers['Content-Type']).to include('application/pdf')
      expect(page.response_headers['Content-Disposition']).to include('offre_commerciale')
    end
  end

  describe 'Mobile commercial management' do
    it 'provides mobile-optimized lot browsing' do
      page.driver.browser.manage.window.resize_to(375, 667)
      
      visit immo_promo_engine.commercial_dashboard_lot_inventory_project_path(project)
      
      expect(page).to have_css('.mobile-lot-browser')
      
      # Swipeable lot cards
      find('.lot-card-mobile', match: :first).swipe_left
      expect(page).to have_css('.lot-actions-mobile')
      
      # Quick filters
      find('.mobile-filter-toggle').click
      expect(page).to have_css('.mobile-filters')
      
      # Interactive building view
      click_button 'Vue 3D'
      expect(page).to have_css('.building-3d-mobile')
    end

    it 'enables on-site reservation creation' do
      page.driver.browser.manage.window.resize_to(375, 667)
      
      visit immo_promo_engine.commercial_dashboard_project_path(project)
      
      find('.mobile-fab').click
      click_link 'Nouvelle réservation'
      
      within('.mobile-reservation-form') do
        select @lots[1].reference, from: 'lot'
        fill_in 'client_name', with: 'Client Mobile'
        fill_in 'client_phone', with: '0612345678'
        
        # Signature pad
        expect(page).to have_css('.signature-pad')
        
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Réservation créée')
    end
  end

  describe 'Real-time availability updates' do
    it 'shows live lot status updates' do
      visit immo_promo_engine.commercial_dashboard_lot_inventory_project_path(project)
      
      # Simulate another user reserving a lot
      in_browser(:two) do
        other_user = create(:user, organization: organization)
        login_as(other_user, scope: :user)
        
        visit immo_promo_engine.commercial_dashboard_lot_inventory_project_path(project)
        
        within("#lot-#{@lots[0].id}") do
          click_button 'Réserver'
        end
        
        within('#reservation-modal') do
          fill_in 'client_name', with: 'Autre Client'
          click_button 'Créer réservation'
        end
      end
      
      # Check update appears in first browser
      within("#lot-#{@lots[0].id}") do
        expect(page).to have_css('.status-reserved', wait: 5)
        expect(page).to have_content('Réservé')
      end
      
      # Notification
      expect(page).to have_css('.availability-update-notification')
      expect(page).to have_content('Un lot vient d\'être réservé')
    end
  end
end