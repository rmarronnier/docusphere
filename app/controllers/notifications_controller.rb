class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:show, :mark_as_read, :destroy]

  def index
    @notifications = policy_scope(Notification)
        .includes(:notifiable)
        .by_category(params[:category])
        .then { |scope| params[:unread_only] == 'true' ? scope.unread : scope }
        .recent
        .page(params[:page])
        .per(20)
    
    @categories = Notification.categories
    @stats = NotificationService.notification_stats_for_user(current_user)
    
    respond_to do |format|
      format.html
      format.json { render json: notification_collection_json }
    end
  end

  def show
    authorize @notification
    @notification.mark_as_read! if @notification.unread?
    
    respond_to do |format|
      format.html
      format.json { render json: notification_json(@notification) }
    end
  end

  def mark_as_read
    authorize @notification
    @notification.mark_as_read!
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.json { render json: notification_json(@notification) }
    end
  end

  def mark_all_as_read
    authorize :notification, :mark_all_as_read?
    NotificationService.mark_all_read_for_user(current_user)
    
    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'Toutes les notifications ont été marquées comme lues.' }
      format.json { render json: { status: 'success', message: 'All notifications marked as read' } }
    end
  end

  def bulk_mark_as_read
    authorize :notification, :bulk_mark_as_read?
    count = NotificationService.bulk_mark_as_read(params[:notification_ids], current_user)
    
    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "#{count} notifications marquées comme lues." }
      format.json { render json: { status: 'success', count: count } }
    end
  end

  def destroy
    authorize @notification
    @notification.destroy!
    
    respond_to do |format|
      format.html { redirect_to notifications_path, notice: 'Notification supprimée.' }
      format.json { render json: { status: 'success' } }
    end
  end

  def bulk_destroy
    authorize :notification, :bulk_destroy?
    count = NotificationService.bulk_delete_notifications(params[:notification_ids], current_user)
    
    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "#{count} notifications supprimées." }
      format.json { render json: { status: 'success', count: count } }
    end
  end

  def dropdown
    authorize :notification, :dropdown?
    @notifications = NotificationService.recent_notifications_for_user(current_user, limit: 10)
    @unread_count = NotificationService.unread_count_for_user(current_user)
    
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
    authorize :notification, :urgent?
    @notifications = NotificationService.urgent_notifications_for_user(current_user)
    
    respond_to do |format|
      format.html
      format.json { render json: @notifications.map { |n| notification_json(n) } }
    end
  end

  def stats
    authorize :notification, :stats?
    @stats = NotificationService.notification_stats_for_user(current_user)
    
    respond_to do |format|
      format.json { render json: @stats }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_params
    params.require(:notification).permit(:read_at)
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
        id: notification.notifiable.id
      } : nil,
      data: notification.formatted_data
    }
  end

  def notification_collection_json
    {
      notifications: @notifications.map { |n| notification_json(n) },
      pagination: {
        current_page: @notifications.current_page,
        total_pages: @notifications.total_pages,
        total_count: @notifications.total_count,
        items_per_page: @notifications.limit_value
      },
      stats: @stats,
      categories: @categories
    }
  end
end