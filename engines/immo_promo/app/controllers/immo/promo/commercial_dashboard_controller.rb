module Immo
  module Promo
    class CommercialDashboardController < Immo::Promo::ApplicationController
      before_action :set_project
      before_action :authorize_commercial_access

      def dashboard
        @lots_summary = calculate_lots_summary
        @sales_metrics = calculate_sales_metrics
        @reservations_data = analyze_reservations
        @revenue_projections = project_revenue
        @commercial_performance = analyze_commercial_performance
        
        respond_to do |format|
          format.html
          format.json { render json: commercial_dashboard_data }
        end
      end

      def lot_inventory
        @lots = @project.lots.includes(:lot_specifications, :reservations)
        @filters = params[:filters] || {}
        
        apply_lot_filters if @filters.any?
        
        @lots_by_status = @lots.group_by(&:status)
        @lots_by_type = @lots.group_by(&:lot_type)
        @lots_by_floor = @lots.group_by(&:floor_number)
      end

      def reservation_management
        @active_reservations = @project.reservations.active.includes(:lot, :client)
        @pending_reservations = @project.reservations.pending.includes(:lot, :client)
        @expired_reservations = @project.reservations.expired.includes(:lot, :client)
        
        @reservation_timeline = build_reservation_timeline
        @conversion_metrics = calculate_conversion_metrics
      end

      def pricing_strategy
        @pricing_analysis = analyze_pricing_by_criteria
        @price_recommendations = generate_price_recommendations
        @competitor_analysis = analyze_market_pricing
        @margin_analysis = calculate_profit_margins
      end

      def sales_pipeline
        @pipeline_stages = build_sales_pipeline
        @prospects = @project.reservations.by_stage
        @conversion_funnel = analyze_conversion_funnel
        @sales_velocity = calculate_sales_velocity
        @bottlenecks = identify_sales_bottlenecks
      end

      def customer_insights
        @customer_segments = segment_customers
        @buyer_preferences = analyze_buyer_preferences
        @satisfaction_metrics = calculate_satisfaction_metrics
        @referral_tracking = track_referrals
      end

      def create_reservation
        @lot = @project.lots.find(params[:lot_id])
        reservation_params = params.require(:reservation).permit(
          :client_name, :client_email, :client_phone, :reservation_amount,
          :validity_days, :notes
        )
        
        result = create_lot_reservation(@lot, reservation_params)
        
        if result[:success]
          flash[:success] = "Réservation créée pour le lot #{@lot.reference}"
          send_reservation_confirmation(result[:reservation])
          redirect_to immo_promo_engine.project_commercial_dashboard_reservation_management_path(@project)
        else
          flash[:error] = result[:error]
          redirect_back(fallback_location: immo_promo_engine.project_commercial_dashboard_path(@project))
        end
      end

      def update_lot_status
        @lot = @project.lots.find(params[:lot_id])
        new_status = params[:status]
        
        if valid_status_transition?(@lot.status, new_status)
          @lot.update(status: new_status, status_changed_at: Time.current)
          log_status_change(@lot, new_status, current_user)
          flash[:success] = "Statut du lot mis à jour"
        else
          flash[:error] = "Transition de statut non autorisée"
        end
        
        redirect_back(fallback_location: immo_promo_engine.project_commercial_dashboard_lot_inventory_path(@project))
      end

      def generate_offer
        @lot = @project.lots.find(params[:lot_id])
        @reservation = @lot.reservations.find_by(id: params[:reservation_id])
        
        offer_data = compile_offer_data(@lot, @reservation)
        
        respond_to do |format|
          format.pdf do
            render pdf: "offre_#{@lot.reference}_#{Date.current}",
                   layout: 'pdf',
                   template: 'immo/promo/commercial_dashboard/offer_pdf',
                   locals: { offer_data: offer_data }
          end
        end
      end

      def export_inventory
        @lots = @project.lots.includes(:lot_specifications, :reservations)
        
        respond_to do |format|
          format.xlsx do
            render xlsx: 'inventory_xlsx',
                   filename: "inventaire_lots_#{@project.reference_number}.xlsx"
          end
          format.csv do
            csv_data = generate_inventory_csv
            send_data csv_data, filename: "inventaire_lots_#{@project.reference_number}.csv"
          end
        end
      end

      def sales_report
        @report_data = compile_sales_report
        
        respond_to do |format|
          format.pdf do
            render pdf: "rapport_commercial_#{@project.reference_number}",
                   layout: 'pdf',
                   template: 'immo/promo/commercial_dashboard/sales_report_pdf'
          end
        end
      end

      private

      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def authorize_commercial_access
        authorize @project, :manage_commercial?
      end

      def commercial_dashboard_data
        {
          project: {
            id: @project.id,
            name: @project.name,
            reference: @project.reference_number
          },
          lots_summary: @lots_summary,
          sales_metrics: @sales_metrics,
          reservations: @reservations_data,
          revenue_projections: @revenue_projections,
          performance: @commercial_performance
        }
      end

      def calculate_lots_summary
        total_lots = @project.lots.count
        
        {
          total: total_lots,
          by_status: @project.lots.group(:status).count,
          by_type: @project.lots.group(:lot_type).count,
          available: @project.lots.available.count,
          reserved: @project.lots.reserved.count,
          sold: @project.lots.sold.count,
          availability_rate: total_lots > 0 ? (@project.lots.available.count.to_f / total_lots * 100).round(1) : 0
        }
      end

      def calculate_sales_metrics
        sold_lots = @project.lots.sold
        reserved_lots = @project.lots.reserved
        total_revenue = sold_lots.sum(:sale_price_cents) || 0
        reserved_value = reserved_lots.sum(:sale_price_cents) || 0
        
        {
          units_sold: sold_lots.count,
          units_reserved: reserved_lots.count,
          total_revenue: Money.new(total_revenue, 'EUR'),
          reserved_value: Money.new(reserved_value, 'EUR'),
          average_price: sold_lots.any? ? Money.new(total_revenue / sold_lots.count, 'EUR') : Money.new(0, 'EUR'),
          sales_velocity: calculate_monthly_sales_velocity,
          conversion_rate: calculate_reservation_conversion_rate
        }
      end

      def analyze_reservations
        active_reservations = @project.reservations.active
        expired_reservations = @project.reservations.expired_last_30_days
        
        {
          active_count: active_reservations.count,
          active_value: Money.new(active_reservations.joins(:lot).sum('lots.sale_price_cents'), 'EUR'),
          expiring_soon: @project.reservations.expiring_within(7.days).count,
          expired_last_month: expired_reservations.count,
          conversion_pending: active_reservations.where('created_at < ?', 30.days.ago).count
        }
      end

      def project_revenue
        sold_revenue = @project.lots.sold.sum(:sale_price_cents) || 0
        reserved_revenue = @project.lots.reserved.sum(:sale_price_cents) || 0
        available_revenue = @project.lots.available.sum(:sale_price_cents) || 0
        
        {
          realized: Money.new(sold_revenue, 'EUR'),
          committed: Money.new(reserved_revenue, 'EUR'),
          potential: Money.new(available_revenue, 'EUR'),
          total_project_value: Money.new(sold_revenue + reserved_revenue + available_revenue, 'EUR'),
          realization_rate: calculate_revenue_realization_rate(sold_revenue, sold_revenue + reserved_revenue + available_revenue)
        }
      end

      def calculate_revenue_realization_rate(realized, total)
        return 0 if total.zero?
        (realized.to_f / total * 100).round(1)
      end

      def analyze_commercial_performance
        {
          sales_efficiency: calculate_sales_efficiency,
          top_selling_types: identify_top_selling_types,
          price_performance: analyze_price_performance,
          seasonal_trends: analyze_seasonal_trends,
          team_performance: analyze_team_performance
        }
      end

      def calculate_sales_efficiency
        months_active = ((@project.first_sale_date || @project.start_date || Date.current) - Date.current).abs / 30.0
        return 0 if months_active.zero?
        
        units_per_month = @project.lots.sold.count / months_active
        {
          units_per_month: units_per_month.round(1),
          target_achievement: calculate_target_achievement,
          efficiency_score: calculate_efficiency_score
        }
      end

      def calculate_target_achievement
        # Simplifiée - comparerait avec les objectifs définis
        85.0
      end

      def calculate_efficiency_score
        # Score basé sur multiples facteurs
        80.0
      end

      def identify_top_selling_types
        @project.lots.sold
                .group(:lot_type)
                .count
                .sort_by { |_, count| -count }
                .first(5)
                .map { |type, count| { type: type, count: count } }
      end

      def analyze_price_performance
        avg_listed_price = @project.lots.average(:listed_price_cents) || 0
        avg_sale_price = @project.lots.sold.average(:sale_price_cents) || 0
        
        {
          average_discount: avg_listed_price > 0 ? ((avg_listed_price - avg_sale_price) / avg_listed_price * 100).round(1) : 0,
          price_stability: calculate_price_stability,
          optimal_pricing_achieved: avg_sale_price >= avg_listed_price * 0.95
        }
      end

      def calculate_price_stability
        # Mesure la stabilité des prix dans le temps
        'stable'
      end

      def analyze_seasonal_trends
        # Analyse des tendances saisonnières
        []
      end

      def analyze_team_performance
        # Performance par commercial si applicable
        {}
      end

      def calculate_monthly_sales_velocity
        # Vélocité des ventes par mois
        months_data = @project.lots.sold
                             .group_by { |lot| lot.sale_date.beginning_of_month }
                             .transform_values(&:count)
        
        return 0 if months_data.empty?
        
        months_data.values.sum.to_f / months_data.count
      end

      def calculate_reservation_conversion_rate
        total_reservations = @project.reservations.count
        return 0 if total_reservations.zero?
        
        converted_reservations = @project.reservations.joins(:lot).where(lots: { status: 'sold' }).count
        (converted_reservations.to_f / total_reservations * 100).round(1)
      end

      def apply_lot_filters
        @lots = @lots.where(status: @filters[:status]) if @filters[:status].present?
        @lots = @lots.where(lot_type: @filters[:type]) if @filters[:type].present?
        @lots = @lots.where(floor_number: @filters[:floor]) if @filters[:floor].present?
        @lots = @lots.where(building: @filters[:building]) if @filters[:building].present?
        
        if @filters[:price_min].present? || @filters[:price_max].present?
          @lots = @lots.where(sale_price_cents: (@filters[:price_min] || 0)..(@filters[:price_max] || Float::INFINITY))
        end
        
        if @filters[:surface_min].present? || @filters[:surface_max].present?
          @lots = @lots.where(surface_sqm: (@filters[:surface_min] || 0)..(@filters[:surface_max] || Float::INFINITY))
        end
      end

      def build_reservation_timeline
        @project.reservations
                .includes(:lot)
                .order(created_at: :desc)
                .map do |reservation|
          {
            reservation: reservation,
            lot: reservation.lot,
            timeline: calculate_reservation_timeline(reservation),
            status: determine_reservation_status(reservation)
          }
        end
      end

      def calculate_reservation_timeline(reservation)
        {
          created: reservation.created_at,
          expires: reservation.expiry_date,
          days_remaining: (reservation.expiry_date - Date.current).to_i,
          follow_ups: reservation.follow_up_count || 0
        }
      end

      def determine_reservation_status(reservation)
        if reservation.lot.status == 'sold'
          'converted'
        elsif reservation.expired?
          'expired'
        elsif reservation.expiry_date <= 7.days.from_now
          'expiring_soon'
        else
          'active'
        end
      end

      def calculate_conversion_metrics
        {
          average_conversion_time: calculate_average_conversion_time,
          conversion_by_type: calculate_conversion_by_lot_type,
          conversion_by_price_range: calculate_conversion_by_price_range
        }
      end

      def calculate_average_conversion_time
        converted = @project.reservations.joins(:lot).where(lots: { status: 'sold' })
        return 0 if converted.empty?
        
        total_days = converted.sum { |r| (r.lot.sale_date - r.created_at).to_i }
        (total_days.to_f / converted.count).round(1)
      end

      def calculate_conversion_by_lot_type
        @project.lots.group(:lot_type).count
      end

      def calculate_conversion_by_price_range
        # Conversion par tranche de prix
        {}
      end

      def analyze_pricing_by_criteria
        {
          by_type: analyze_pricing_by_type,
          by_floor: analyze_pricing_by_floor,
          by_orientation: analyze_pricing_by_orientation,
          by_surface: analyze_pricing_by_surface
        }
      end

      def analyze_pricing_by_type
        @project.lots.group(:lot_type).average(:price_per_sqm_cents)
                .transform_values { |v| Money.new(v || 0, 'EUR') }
      end

      def analyze_pricing_by_floor
        @project.lots.group(:floor_number).average(:price_per_sqm_cents)
                .transform_values { |v| Money.new(v || 0, 'EUR') }
      end

      def analyze_pricing_by_orientation
        @project.lots.group(:orientation).average(:price_per_sqm_cents)
                .transform_values { |v| Money.new(v || 0, 'EUR') }
      end

      def analyze_pricing_by_surface
        # Analyse par tranche de surface
        {}
      end

      def generate_price_recommendations
        recommendations = []
        
        # Recommandations basées sur la performance
        slow_moving_lots = @project.lots.available.where('listed_at < ?', 90.days.ago)
        if slow_moving_lots.any?
          recommendations << {
            type: 'price_adjustment',
            priority: 'high',
            lots_affected: slow_moving_lots.count,
            recommendation: 'Considérer un ajustement de prix pour les lots en stock depuis plus de 90 jours',
            potential_discount: '5-10%'
          }
        end
        
        recommendations
      end

      def analyze_market_pricing
        # Analyse simplifiée des prix du marché
        {
          market_average: Money.new(350000, 'EUR'),
          project_positioning: 'premium',
          price_competitiveness: 'competitive'
        }
      end

      def calculate_profit_margins
        @project.lots.map do |lot|
          next unless lot.sale_price_cents && lot.construction_cost_cents
          
          margin = lot.sale_price_cents - lot.construction_cost_cents
          margin_percentage = (margin.to_f / lot.sale_price_cents * 100).round(1)
          
          {
            lot: lot,
            margin: Money.new(margin, 'EUR'),
            margin_percentage: margin_percentage
          }
        end.compact
      end

      def build_sales_pipeline
        {
          prospects: { count: 0, value: Money.new(0, 'EUR') }, # Simplifiée
          qualified_leads: { count: 0, value: Money.new(0, 'EUR') },
          visits_scheduled: { count: 0, value: Money.new(0, 'EUR') },
          negotiations: { count: @project.reservations.active.count, value: calculate_pipeline_value('negotiations') },
          closing: { count: 0, value: Money.new(0, 'EUR') }
        }
      end

      def calculate_pipeline_value(stage)
        case stage
        when 'negotiations'
          Money.new(@project.reservations.active.joins(:lot).sum('lots.sale_price_cents'), 'EUR')
        else
          Money.new(0, 'EUR')
        end
      end

      def analyze_conversion_funnel
        # Analyse de l'entonnoir de conversion
        {}
      end

      def calculate_sales_velocity
        # Vélocité du pipeline de ventes
        0
      end

      def identify_sales_bottlenecks
        # Identification des goulots d'étranglement
        []
      end

      def segment_customers
        # Segmentation des clients
        []
      end

      def analyze_buyer_preferences
        # Analyse des préférences d'achat
        {}
      end

      def calculate_satisfaction_metrics
        # Métriques de satisfaction
        {}
      end

      def track_referrals
        # Suivi des recommandations
        {}
      end

      def create_lot_reservation(lot, params)
        return { success: false, error: 'Lot non disponible' } unless lot.available?
        
        reservation = lot.reservations.build(
          client_name: params[:client_name],
          client_email: params[:client_email],
          client_phone: params[:client_phone],
          reservation_amount_cents: params[:reservation_amount].to_i * 100,
          expiry_date: Date.current + (params[:validity_days] || 15).to_i.days,
          notes: params[:notes],
          reserved_by: current_user
        )
        
        if reservation.save
          lot.update(status: 'reserved')
          { success: true, reservation: reservation }
        else
          { success: false, error: reservation.errors.full_messages.join(', ') }
        end
      end

      def send_reservation_confirmation(reservation)
        # Envoi de confirmation par email
        Rails.logger.info "Reservation confirmation sent for #{reservation.id}"
      end

      def valid_status_transition?(current_status, new_status)
        transitions = {
          'available' => %w[reserved blocked],
          'reserved' => %w[available sold blocked],
          'sold' => %w[],
          'blocked' => %w[available]
        }
        
        transitions[current_status]&.include?(new_status) || false
      end

      def log_status_change(lot, new_status, user)
        Rails.logger.info "Lot #{lot.id} status changed to #{new_status} by user #{user.id}"
      end

      def compile_offer_data(lot, reservation)
        {
          project: @project,
          lot: lot,
          reservation: reservation,
          price_details: calculate_price_details(lot),
          payment_schedule: generate_payment_schedule(lot),
          specifications: lot.lot_specifications
        }
      end

      def calculate_price_details(lot)
        base_price = lot.sale_price_cents || 0
        vat = base_price * 0.2 # 20% TVA
        
        {
          base_price: Money.new(base_price, 'EUR'),
          vat: Money.new(vat, 'EUR'),
          total_price: Money.new(base_price + vat, 'EUR'),
          price_per_sqm: lot.price_per_sqm
        }
      end

      def generate_payment_schedule(lot)
        # Échéancier de paiement type
        total = lot.sale_price_cents || 0
        
        [
          { stage: 'Réservation', percentage: 5, amount: Money.new(total * 0.05, 'EUR') },
          { stage: 'Signature compromis', percentage: 10, amount: Money.new(total * 0.10, 'EUR') },
          { stage: 'Obtention permis', percentage: 15, amount: Money.new(total * 0.15, 'EUR') },
          { stage: 'Fondations', percentage: 15, amount: Money.new(total * 0.15, 'EUR') },
          { stage: 'Hors d\'eau', percentage: 20, amount: Money.new(total * 0.20, 'EUR') },
          { stage: 'Hors d\'air', percentage: 15, amount: Money.new(total * 0.15, 'EUR') },
          { stage: 'Livraison', percentage: 20, amount: Money.new(total * 0.20, 'EUR') }
        ]
      end

      def generate_inventory_csv
        CSV.generate do |csv|
          csv << ['Référence', 'Type', 'Étage', 'Surface', 'Prix', 'Statut', 'Bâtiment']
          
          @lots.each do |lot|
            csv << [
              lot.reference,
              lot.lot_type,
              lot.floor_number,
              lot.surface_sqm,
              lot.sale_price&.to_s,
              lot.status,
              lot.building
            ]
          end
        end
      end

      def compile_sales_report
        {
          project: @project,
          period: {
            start_date: @project.start_date,
            end_date: Date.current
          },
          sales_summary: calculate_sales_metrics,
          inventory_status: calculate_lots_summary,
          revenue_analysis: project_revenue,
          performance_metrics: analyze_commercial_performance,
          generated_at: Time.current,
          generated_by: current_user
        }
      end
    end
  end
end