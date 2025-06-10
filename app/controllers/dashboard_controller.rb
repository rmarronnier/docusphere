class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_profile
  before_action :load_widget, only: [:update_widget, :refresh_widget]
  
  # Skip CSRF protection for JSON API requests
  protect_from_forgery except: [:update_widget, :refresh_widget, :reorder_widgets]
  
  def show
    service = DashboardPersonalizationService.new(current_user)
    @dashboard_data = service.personalized_dashboard
  end
  
  def update_widget
    if @widget.update(widget_params)
      render json: { status: 'success', widget: widget_data(@widget) }
    else
      render json: { status: 'error', errors: @widget.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def reorder_widgets
    unless current_user
      render json: { error: 'Authentication required' }, status: :unauthorized
      return
    end
    
    widget_ids = params[:widget_ids] || []
    user_widget_ids = current_user.active_profile.dashboard_widgets.pluck(:id)
    
    # Only reorder widgets that belong to the current user
    valid_widget_ids = widget_ids.select { |id| user_widget_ids.include?(id.to_i) }
    
    valid_widget_ids.each_with_index do |widget_id, index|
      current_user.active_profile.dashboard_widgets.find(widget_id).update(position: index + 1)
    end
    
    render json: { status: 'success' }
  end
  
  def refresh_widget
    # Update last refreshed timestamp
    @widget.config['last_refreshed_at'] = Time.current.iso8601
    @widget.save
    
    # Get fresh widget data
    service = DashboardPersonalizationService.new(current_user)
    widget_data = service.widget_data_for(@widget)
    
    render json: { status: 'success', widget: widget_data }
  end
  
  private
  
  def ensure_user_profile
    return if current_user.active_profile
    
    # Create a default profile if none exists
    profile = UserProfile.create!(
      user: current_user,
      profile_type: 'assistant_rh',
      active: true
    )
    
    # Reload the association to ensure it's available
    current_user.reload
  end
  
  def load_widget
    @widget = current_user.active_profile.dashboard_widgets.find_by(id: params[:id])
    
    if @widget.nil?
      render json: { status: 'error', message: 'Widget not found' }, status: :not_found
    end
  end
  
  def widget_params
    permitted = params.require(:widget).permit(:position, :width, :height, config: {})
    
    # Convert config values to appropriate types
    if permitted[:config]
      permitted[:config].each do |key, value|
        # Convert numeric strings to integers
        if value.is_a?(String) && value.match?(/\A\d+\z/)
          permitted[:config][key] = value.to_i
        end
      end
    end
    
    permitted
  end
  
  def widget_data(widget)
    {
      id: widget.id,
      widget_type: widget.widget_type,
      position: widget.position,
      width: widget.width,
      height: widget.height,
      config: widget.config
    }
  end
end