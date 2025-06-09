class NotificationPreferencesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    current_user.ensure_notification_preferences!
    @preferences = current_user.user_notification_preferences
                                .includes(:user)
                                .order(:notification_type)
    @categories = group_preferences_by_category
  end

  def update
    @preference = current_user.user_notification_preferences
                              .find_or_initialize_by(notification_type: params[:id])
    
    if @preference.update(preference_params)
      respond_to do |format|
        format.html { redirect_to notification_preferences_path, notice: 'Préférences mises à jour avec succès.' }
        format.json { render json: { status: 'success', preference: preference_json(@preference) } }
      end
    else
      respond_to do |format|
        format.html { redirect_to notification_preferences_path, alert: 'Erreur lors de la mise à jour des préférences.' }
        format.json { render json: { status: 'error', errors: @preference.errors.full_messages } }
      end
    end
  end

  def bulk_update
    preferences_params = params[:preferences] || {}
    updated_count = 0
    errors = []

    preferences_params.each do |notification_type, preference_data|
      preference = current_user.user_notification_preferences
                               .find_or_initialize_by(notification_type: notification_type)
      
      if preference.update(preference_data.permit(:delivery_method, :frequency, :enabled))
        updated_count += 1
      else
        errors << "#{notification_type}: #{preference.errors.full_messages.join(', ')}"
      end
    end

    if errors.empty?
      redirect_to notification_preferences_path, 
                  notice: "#{updated_count} préférences mises à jour avec succès."
    else
      redirect_to notification_preferences_path,
                  alert: "Erreurs lors de la mise à jour: #{errors.join('; ')}"
    end
  end

  def reset_to_defaults
    current_user.user_notification_preferences.destroy_all
    current_user.ensure_notification_preferences!
    
    respond_to do |format|
      format.html { redirect_to notification_preferences_path, notice: 'Préférences réinitialisées aux valeurs par défaut.' }
      format.json { render json: { status: 'success', message: 'Preferences reset to defaults' } }
    end
  end

  def preview
    @notification_type = params[:notification_type]
    @notification = build_preview_notification
    
    respond_to do |format|
      format.html { render partial: 'preview_notification' }
      format.json { render json: notification_json(@notification) }
    end
  end

  private

  def preference_params
    params.require(:user_notification_preference).permit(:delivery_method, :frequency, :enabled)
  end

  def group_preferences_by_category
    categories = {}
    
    Notification.categories.each do |category|
      notification_types = Notification.notification_types_by_category(category)
      categories[category] = @preferences.select { |p| notification_types.include?(p.notification_type) }
    end
    
    categories
  end

  def preference_json(preference)
    {
      id: preference.id,
      notification_type: preference.notification_type,
      delivery_method: preference.delivery_method,
      frequency: preference.frequency,
      enabled: preference.enabled,
      display_name: preference.display_name,
      description: preference.description,
      category: preference.category,
      urgent: preference.urgent_notification?
    }
  end

  def notification_json(notification)
    {
      title: notification.title,
      message: notification.message,
      notification_type: notification.notification_type,
      icon: notification.icon,
      color_class: notification.color_class,
      category: notification.category,
      urgent: notification.urgent?
    }
  end

  def build_preview_notification
    case @notification_type
    when 'document_shared'
      OpenStruct.new(
        title: "Document partagé",
        message: "Jean Dupont a partagé le document 'Rapport mensuel.pdf' avec vous",
        notification_type: @notification_type,
        icon: 'share',
        color_class: 'text-blue-600',
        category: 'documents',
        urgent?: false
      )
    when 'project_task_assigned'
      OpenStruct.new(
        title: "Nouvelle tâche assignée",
        message: "Marie Martin vous a assigné la tâche 'Révision des plans' dans le projet 'Résidence Les Jardins'",
        notification_type: @notification_type,
        icon: 'user-check',
        color_class: 'text-purple-600',
        category: 'projects',
        urgent?: false
      )
    when 'budget_exceeded'
      OpenStruct.new(
        title: "Budget dépassé",
        message: "Le budget 'Gros œuvre' du projet 'Résidence Les Jardins' a été dépassé de 15 000€",
        notification_type: @notification_type,
        icon: 'alert-triangle',
        color_class: 'text-red-600',
        category: 'budgets',
        urgent?: true
      )
    else
      OpenStruct.new(
        title: "Notification d'exemple",
        message: "Ceci est un exemple de notification pour le type '#{@notification_type.humanize}'",
        notification_type: @notification_type,
        icon: 'info',
        color_class: 'text-gray-600',
        category: 'system',
        urgent?: false
      )
    end
  end
end