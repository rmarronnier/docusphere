module Immo
  module Promo
    class NotificationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_notification, only: [:show, :mark_as_read, :destroy]

      def index
        @pagy, @notifications = pagy(
          current_user.notifications
            .includes(:notifiable)
            .by_category(immo_promo_categories)
            .then { |scope| params[:unread_only] == 'true' ? scope.unread : scope }
            .recent,
          items: 20
        )
        
        @categories = immo_promo_categories
        @stats = immo_promo_notification_stats
        
        respond_to do |format|
          format.html
          format.json { render json: notification_collection_json }
        end
      end

      def show
        authorize_notification_access!
        @notification.mark_as_read! if @notification.unread?
        
        respond_to do |format|
          format.html
          format.json { render json: notification_json(@notification) }
        end
      end

      def mark_as_read
        authorize_notification_access!
        @notification.mark_as_read!
        
        respond_to do |format|
          format.html { redirect_back(fallback_location: immo_promo_engine.notifications_path) }
          format.json { render json: notification_json(@notification) }
        end
      end

      def mark_all_as_read
        NotificationService.mark_all_read_for_user(current_user)
        
        respond_to do |format|
          format.html { redirect_to immo_promo_engine.notifications_path, notice: 'Toutes les notifications ont été marquées comme lues.' }
          format.json { render json: { status: 'success', message: 'All notifications marked as read' } }
        end
      end

      def bulk_mark_as_read
        count = NotificationService.bulk_mark_as_read(params[:notification_ids], current_user)
        
        respond_to do |format|
          format.html { redirect_to immo_promo_engine.notifications_path, notice: "#{count} notifications marquées comme lues." }
          format.json { render json: { status: 'success', count: count } }
        end
      end

      def destroy
        authorize_notification_access!
        @notification.destroy!
        
        respond_to do |format|
          format.html { redirect_to immo_promo_engine.notifications_path, notice: 'Notification supprimée.' }
          format.json { render json: { status: 'success' } }
        end
      end

      def bulk_destroy
        count = NotificationService.bulk_delete_notifications(params[:notification_ids], current_user)
        
        respond_to do |format|
          format.html { redirect_to immo_promo_engine.notifications_path, notice: "#{count} notifications supprimées." }
          format.json { render json: { status: 'success', count: count } }
        end
      end

      def dropdown
        @notifications = current_user.notifications
                                    .by_category(immo_promo_categories)
                                    .recent
                                    .limit(10)
        @unread_count = current_user.notifications
                                   .by_category(immo_promo_categories)
                                   .unread
                                   .count
        
        respond_to do |format|
          format.html { render partial: 'dropdown' }
          format.json { 
            render json: {
              notifications: @notifications.map { |n| notification_json(n) },
              unread_count: @unread_count
            }
          }
        end
      end

      def urgent
        @notifications = current_user.notifications
                                    .by_category(immo_promo_categories)
                                    .urgent
                                    .unread
                                    .recent
        
        respond_to do |format|
          format.html
          format.json { render json: @notifications.map { |n| notification_json(n) } }
        end
      end

      def project_notifications
        @project = Immo::Promo::Project.find(params[:project_id])
        authorize @project, :show?
        
        @pagy, @notifications = pagy(
          current_user.notifications
            .joins(:notifiable)
            .where(notifiable: [@project, @project.phases, @project.tasks, @project.stakeholders, 
                               @project.permits, @project.budgets, @project.risks])
            .recent,
          items: 20
        )
        
        respond_to do |format|
          format.html
          format.json { render json: notification_collection_json }
        end
      end

      def stats
        respond_to do |format|
          format.json { render json: immo_promo_notification_stats }
        end
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      end

      def authorize_notification_access!
        # Check if notification is ImmoPromo-related
        unless @notification.immo_promo_related? || @notification.system?
          redirect_to immo_promo_engine.root_path, alert: 'Accès non autorisé.'
        end
      end

      def immo_promo_categories
        %w[projects stakeholders permits budgets risks]
      end

      def immo_promo_notification_stats
        notifications = current_user.notifications.by_category(immo_promo_categories)
        {
          total: notifications.count,
          unread: notifications.unread.count,
          urgent: notifications.urgent.unread.count,
          today: notifications.today.count,
          this_week: notifications.this_week.count,
          by_category: immo_promo_categories.map do |category|
            [category, notifications.by_category(category).count]
          end.to_h
        }
      end

      def notification_json(notification)
        {
          id: notification.id,
          title: notification.title,
          message: notification.message,
          notification_type: notification.notification_type,
          icon: notification.icon,
          color_class: notification.color_class,
          category: notification.category,
          urgent: notification.urgent?,
          read: notification.read?,
          time_ago: notification.time_ago,
          created_at: notification.created_at,
          notifiable: notification.notifiable ? {
            type: notification.notifiable.class.name,
            id: notification.notifiable.id,
            url: notifiable_url(notification.notifiable)
          } : nil,
          data: notification.formatted_data
        }
      end

      def notifiable_url(notifiable)
        case notifiable
        when Immo::Promo::Project
          immo_promo_engine.project_path(notifiable)
        when Immo::Promo::Phase
          immo_promo_engine.project_phase_path(notifiable.project, notifiable)
        when Immo::Promo::Task
          immo_promo_engine.project_phase_task_path(notifiable.phase.project, notifiable.phase, notifiable)
        when Immo::Promo::Stakeholder
          immo_promo_engine.project_stakeholder_path(notifiable.project, notifiable)
        when Immo::Promo::Permit
          immo_promo_engine.project_permit_path(notifiable.project, notifiable)
        when Immo::Promo::Budget
          immo_promo_engine.project_budget_path(notifiable.project, notifiable)
        when Immo::Promo::Risk
          immo_promo_engine.project_risk_path(notifiable.project, notifiable)
        else
          nil
        end
      end

      def notification_collection_json
        {
          notifications: @notifications.map { |n| notification_json(n) },
          pagination: {
            current_page: @pagy.page,
            total_pages: @pagy.pages,
            total_count: @pagy.count,
            items_per_page: @pagy.items
          },
          stats: @stats,
          categories: @categories
        }
      end
    end
  end
end