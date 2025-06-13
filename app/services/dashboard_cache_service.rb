# frozen_string_literal: true

class DashboardCacheService
  include Cacheable
  include Calculable

  # Configure caching for dashboard
  cache_expires_in 15.minutes
  cache_namespace 'dashboard'

  def initialize(user)
    @user = user
    @organization = user.organization
    @profile_type = user.active_profile&.profile_type
    
    super() # Initialize Cacheable concern
  end

  # Cache dashboard widgets data with smart invalidation
  def cached_widget_data(widget_type, force_refresh: false)
    cache_key = "#{@user.id}:#{@profile_type}:#{widget_type}"
    
    if force_refresh
      invalidate_cache(cache_key)
    end

    # Use Cacheable concern with dependencies
    cached_with_dependencies(
      cache_key,
      dependencies: widget_dependencies(widget_type),
      expires_in: cache_expiry_for_widget(widget_type)
    ) do
      calculate_widget_data(widget_type)
    end
  end

  # Invalidate specific widget cache with cascade
  def invalidate_widget_cache(widget_type)
    cache_key = "#{@user.id}:#{@profile_type}:#{widget_type}"
    invalidate_cache(cache_key)
    
    # Cascade invalidation to related widgets
    related_widgets(widget_type).each do |related_widget|
      related_key = "#{@user.id}:#{@profile_type}:#{related_widget}"
      invalidate_cache(related_key)
    end
  end

  # Preload cache for multiple widgets
  def preload_widgets_cache(widget_types = [])
    widget_types = default_widgets_for_profile if widget_types.empty?
    
    # Use batch_cache from Cacheable concern
    widget_data_map = {}
    
    widget_types.each do |widget_type|
      cache_key = "#{@user.id}:#{@profile_type}:#{widget_type}"
      widget_data_map[cache_key] = calculate_widget_data(widget_type)
    end
    
    # Warm cache with all computed data
    warm_cache(widget_data_map)
  end

  # Get comprehensive cache statistics
  def cache_statistics
    widgets = default_widgets_for_profile
    
    widgets.map do |widget_type|
      cache_key = "#{@user.id}:#{@profile_type}:#{widget_type}"
      stats = cache_stats(cache_key)
      
      stats.merge(
        widget_type: widget_type,
        dependencies: widget_dependencies(widget_type).size,
        expiry_time: cache_expiry_for_widget(widget_type)
      )
    end
  end

  # Background refresh with smart timing
  def schedule_background_refresh
    widget_types = default_widgets_for_profile
    
    widget_types.each do |widget_type|
      cache_key = "#{@user.id}:#{@profile_type}:#{widget_type}"
      
      # Use cached_with_refresh from Cacheable concern
      cached_with_refresh(
        cache_key,
        refresh_threshold: 0.7, # Refresh when 70% of TTL elapsed
        expires_in: cache_expiry_for_widget(widget_type)
      ) do
        calculate_widget_data(widget_type)
      end
    end
  end

  private

  def calculate_widget_data(widget_type)
    case widget_type
    when :recent_documents
      calculate_recent_documents_data
    when :pending_documents
      calculate_pending_documents_data
    when :project_documents
      calculate_project_documents_data
    when :validation_queue
      calculate_validation_queue_data
    when :compliance_alerts
      calculate_compliance_alerts_data
    when :recent_activity
      calculate_recent_activity_data
    when :statistics
      calculate_statistics_data
    when :client_documents
      calculate_client_documents_data
    else
      {}
    end
  end

  def calculate_recent_documents_data
    documents = Document.joins(:space)
                       .where(spaces: { organization: @organization })
                       .accessible_by(@user)
                       .recent
                       .limit(10)
                       .includes(:uploaded_by, :tags, :file_attachment)

    {
      documents: documents.map { |doc| document_summary(doc) },
      total_count: documents.size,
      last_updated: Time.current
    }
  end

  def calculate_pending_documents_data
    # Documents requiring user action
    pending_docs = Document.joins(:space)
                          .where(spaces: { organization: @organization })
                          .accessible_by(@user)
                          .where(status: ['draft', 'pending_review', 'locked'])
                          .includes(:uploaded_by, :validation_requests)

    {
      documents: pending_docs.map { |doc| document_summary(doc) },
      counts_by_status: pending_docs.group(:status).count,
      total_count: pending_docs.size,
      urgency_distribution: calculate_urgency_distribution(pending_docs)
    }
  end

  def calculate_project_documents_data
    return {} unless defined?(Immo::Promo::Project)
    
    # Documents linked to user's projects
    user_projects = Immo::Promo::Project.where(organization: @organization)
                                       .accessible_by(@user)

    project_docs = Document.where(documentable: user_projects)
                          .includes(:documentable, :uploaded_by)
                          .recent
                          .limit(20)

    projects_summary = user_projects.map do |project|
      docs_count = project_docs.select { |doc| doc.documentable_id == project.id }.size
      {
        project: project_summary(project),
        documents_count: docs_count,
        last_activity: project.updated_at
      }
    end

    {
      projects: projects_summary,
      recent_documents: project_docs.first(5).map { |doc| document_summary(doc) },
      total_projects: user_projects.size,
      total_documents: project_docs.size
    }
  end

  def calculate_validation_queue_data
    # Documents awaiting validation from this user
    validation_requests = ValidationRequest.joins(:validatable)
                                          .where(validatable_type: 'Document')
                                          .where(status: 'pending')
                                          .where(validator: @user)
                                          .includes(:validatable, :requestor)

    grouped_by_priority = validation_requests.group_by(&:priority)

    {
      requests: validation_requests.map { |req| validation_summary(req) },
      counts_by_priority: grouped_by_priority.transform_values(&:size),
      total_count: validation_requests.size,
      avg_waiting_time: calculate_average_waiting_time(validation_requests)
    }
  end

  def calculate_compliance_alerts_data
    alerts = []
    
    # Documents expiring soon
    expiring_docs = Document.joins(:space)
                           .where(spaces: { organization: @organization })
                           .where('expiry_date <= ?', 30.days.from_now)
                           .where('expiry_date > ?', Date.current)

    expiring_docs.each do |doc|
      days_until_expiry = (doc.expiry_date - Date.current).to_i
      urgency = case days_until_expiry
                when 0..7 then :critical
                when 8..14 then :high
                else :medium
                end
      
      alerts << {
        type: :expiring_document,
        urgency: urgency,
        document: document_summary(doc),
        days_remaining: days_until_expiry,
        message: "Document expire dans #{days_until_expiry} jour(s)"
      }
    end

    # Add more compliance checks here based on business rules
    
    {
      alerts: alerts.sort_by { |alert| alert[:urgency] == :critical ? 0 : 1 },
      counts_by_urgency: alerts.group_by { |a| a[:urgency] }.transform_values(&:size),
      total_count: alerts.size
    }
  end

  def calculate_recent_activity_data
    # Recent activities across the organization
    activities = []
    
    # Document activities
    recent_docs = Document.joins(:space)
                         .where(spaces: { organization: @organization })
                         .where('updated_at > ?', 7.days.ago)
                         .includes(:uploaded_by)
                         .order(updated_at: :desc)
                         .limit(20)

    recent_docs.each do |doc|
      activities << {
        type: :document_update,
        timestamp: doc.updated_at,
        actor: user_summary(doc.uploaded_by),
        target: document_summary(doc),
        description: "Document mis à jour"
      }
    end

    # Sort by timestamp and limit
    sorted_activities = activities.sort_by { |a| a[:timestamp] }.reverse.first(15)

    {
      activities: sorted_activities,
      total_count: sorted_activities.size,
      activity_by_day: group_activities_by_day(sorted_activities)
    }
  end

  def calculate_statistics_data
    base_query = Document.joins(:space).where(spaces: { organization: @organization })
    
    # Use Calculable concern methods
    total_documents = base_query.count
    total_size = base_query.joins(:file_attachment).sum('active_storage_blobs.byte_size')
    
    # Documents by status
    status_distribution = base_query.group(:status).count
    
    # Recent growth
    last_month_docs = base_query.where('created_at > ?', 1.month.ago).count
    growth_rate = calculate_trend(total_documents - last_month_docs, total_documents)

    {
      totals: {
        documents: total_documents,
        size: format_file_size(total_size),
        users: @organization.users.count
      },
      distributions: {
        by_status: status_distribution,
        by_type: calculate_type_distribution(base_query)
      },
      trends: {
        monthly_growth: format_number(growth_rate, type: :percentage),
        documents_this_month: last_month_docs
      },
      performance: {
        avg_processing_time: calculate_avg_processing_time,
        cache_hit_rate: calculate_cache_hit_rate
      }
    }
  end

  def calculate_client_documents_data
    # For commercial profile - documents shared with clients
    shared_docs = DocumentShare.joins(:document)
                              .where(documents: { organization: @organization })
                              .where(shared_with_type: 'Client')
                              .includes(:document, :shared_with)
                              .recent
                              .limit(20)

    grouped_by_client = shared_docs.group_by(&:shared_with)

    {
      shared_documents: shared_docs.map { |share| share_summary(share) },
      clients: grouped_by_client.keys.map { |client| client_summary(client) },
      total_shares: shared_docs.size,
      recent_activity: shared_docs.first(5).map { |share| share_activity(share) }
    }
  end

  # Cache dependencies for each widget type
  def widget_dependencies(widget_type)
    case widget_type
    when :recent_documents, :pending_documents
      [Document, @user]
    when :project_documents
      [Document, Immo::Promo::Project, @user] if defined?(Immo::Promo::Project)
    when :validation_queue
      [ValidationRequest, @user]
    when :compliance_alerts
      [Document, @organization]
    when :statistics
      [Document, @organization]
    else
      [@user]
    end.compact
  end

  def cache_expiry_for_widget(widget_type)
    case widget_type
    when :recent_documents, :recent_activity
      5.minutes  # Frequent updates
    when :statistics, :compliance_alerts
      30.minutes # Less frequent updates
    when :validation_queue, :pending_documents
      10.minutes # Medium frequency
    else
      15.minutes # Default
    end
  end

  def related_widgets(widget_type)
    case widget_type
    when :recent_documents
      [:recent_activity, :statistics]
    when :validation_queue
      [:pending_documents, :compliance_alerts]
    when :project_documents
      [:recent_activity, :statistics]
    else
      []
    end
  end

  def default_widgets_for_profile
    case @profile_type
    when 'direction'
      [:validation_queue, :compliance_alerts, :statistics, :recent_activity]
    when 'chef_projet'
      [:project_documents, :pending_documents, :recent_activity]
    when 'commercial'
      [:client_documents, :recent_documents, :statistics]
    when 'juridique'
      [:compliance_alerts, :validation_queue, :recent_documents]
    else
      [:recent_documents, :pending_documents, :recent_activity, :statistics]
    end
  end

  # Helper methods for data formatting
  def document_summary(document)
    {
      id: document.id,
      title: document.title,
      status: document.status,
      uploaded_by: user_summary(document.uploaded_by),
      updated_at: document.updated_at,
      size: format_file_size(document.file_size),
      url: document_path(document)
    }
  end

  def user_summary(user)
    return nil unless user
    
    {
      id: user.id,
      name: user.display_name,
      email: user.email
    }
  end

  def project_summary(project)
    {
      id: project.id,
      name: project.name,
      status: project.status,
      progress: calculate_project_progress(project)
    }
  end

  def validation_summary(validation_request)
    {
      id: validation_request.id,
      document: document_summary(validation_request.validatable),
      requestor: user_summary(validation_request.requestor),
      priority: validation_request.priority,
      requested_at: validation_request.created_at
    }
  end

  def format_file_size(bytes)
    return '0 B' if bytes.nil? || bytes.zero?
    
    units = ['B', 'KB', 'MB', 'GB']
    exp = (Math.log(bytes) / Math.log(1024)).floor
    exp = [exp, units.length - 1].min
    
    size = (bytes.to_f / (1024 ** exp)).round(1)
    "#{size} #{units[exp]}"
  end

  def calculate_urgency_distribution(documents)
    urgency_counts = { low: 0, medium: 0, high: 0, critical: 0 }
    
    documents.each do |doc|
      urgency = case doc.status
               when 'draft' then :low
               when 'pending_review' then :medium
               when 'locked' then :high
               else :low
               end
      urgency_counts[urgency] += 1
    end
    
    urgency_counts
  end

  def calculate_average_waiting_time(validation_requests)
    return 0 if validation_requests.empty?
    
    waiting_times = validation_requests.map do |req|
      (Time.current - req.created_at) / 1.day
    end
    
    (waiting_times.sum / waiting_times.size).round(1)
  end

  def group_activities_by_day(activities)
    activities.group_by { |a| a[:timestamp].to_date }
              .transform_values(&:size)
  end

  def calculate_type_distribution(query)
    query.joins(:file_attachment)
         .group('active_storage_blobs.content_type')
         .count
         .transform_keys { |ct| content_type_label(ct) }
  end

  def calculate_avg_processing_time
    # Simplified calculation - would need more sophisticated tracking
    5.2 # seconds (placeholder)
  end

  def calculate_cache_hit_rate
    # Would require actual cache statistics
    0.85 # 85% (placeholder)
  end

  def content_type_label(content_type)
    case content_type
    when 'application/pdf' then 'PDF'
    when /image/ then 'Images'
    when /video/ then 'Vidéos'
    when /text/ then 'Texte'
    else 'Autres'
    end
  end

  def document_path(document)
    "/ged/documents/#{document.id}"
  end
end