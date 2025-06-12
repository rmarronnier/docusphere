# frozen_string_literal: true

class DashboardCacheService
  CACHE_EXPIRY = 15.minutes
  CACHE_VERSION = 'v2'

  def initialize(user)
    @user = user
    @organization = user.organization
    @profile_type = user.active_profile&.profile_type
  end

  # Cache dashboard widgets data with smart invalidation
  def cached_widget_data(widget_type, force_refresh: false)
    cache_key = widget_cache_key(widget_type)
    
    if force_refresh
      Rails.cache.delete(cache_key)
    end

    Rails.cache.fetch(cache_key, expires_in: cache_expiry_for_widget(widget_type)) do
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
      else
        {}
      end
    end
  end

  # Invalidate specific widget cache
  def invalidate_widget_cache(widget_type)
    cache_key = widget_cache_key(widget_type)
    Rails.cache.delete(cache_key)
    
    # Also invalidate related widgets
    related_widgets(widget_type).each do |related_widget|
      Rails.cache.delete(widget_cache_key(related_widget))
    end
  end

  # Invalidate all user dashboard cache
  def invalidate_all_cache
    cache_pattern = "dashboard:#{@user.id}:#{@profile_type}:*"
    Rails.cache.delete_matched(cache_pattern)
  end

  # Preload cache for multiple widgets (async)
  def preload_widgets_cache(widget_types = [])
    widget_types = default_widgets_for_profile if widget_types.empty?
    
    # Use background job for heavy computation
    PreloadDashboardCacheJob.perform_later(@user.id, widget_types)
  end

  # Get cache statistics for debugging
  def cache_statistics
    widgets = default_widgets_for_profile
    stats = {}
    
    widgets.each do |widget_type|
      cache_key = widget_cache_key(widget_type)
      cached_data = Rails.cache.read(cache_key)
      
      stats[widget_type] = {
        cached: cached_data.present?,
        cache_key: cache_key,
        data_size: cached_data&.to_s&.bytesize || 0,
        expires_at: Rails.cache.instance_variable_get(:@data)&.dig(cache_key)&.expires_at
      }
    end
    
    stats
  end

  private

  attr_reader :user, :organization, :profile_type

  def widget_cache_key(widget_type)
    # Include user_id, profile_type, and organization for cache segmentation
    "dashboard:#{@user.id}:#{@profile_type}:#{widget_type}:#{CACHE_VERSION}"
  end

  def cache_expiry_for_widget(widget_type)
    case widget_type
    when :recent_activity
      5.minutes  # Most dynamic content
    when :pending_documents, :validation_queue
      10.minutes # Important but less frequent changes
    when :statistics, :compliance_alerts
      CACHE_EXPIRY # Standard expiry
    when :project_documents
      30.minutes # Less frequent updates
    else
      CACHE_EXPIRY
    end
  end

  def related_widgets(widget_type)
    relationships = {
      recent_documents: [:statistics, :recent_activity],
      pending_documents: [:validation_queue, :statistics],
      project_documents: [:statistics, :compliance_alerts],
      validation_queue: [:pending_documents, :recent_activity],
      compliance_alerts: [:project_documents, :statistics],
      recent_activity: [:recent_documents, :validation_queue],
      statistics: [] # Statistics affect multiple widgets but don't need cascading
    }
    
    relationships[widget_type] || []
  end

  def default_widgets_for_profile
    case @profile_type
    when 'direction'
      [:statistics, :validation_queue, :compliance_alerts, :recent_activity, :project_documents]
    when 'chef_projet'
      [:project_documents, :pending_documents, :recent_activity, :statistics]
    when 'commercial'
      [:project_documents, :recent_documents, :recent_activity, :statistics]
    when 'juriste'
      [:validation_queue, :compliance_alerts, :pending_documents, :recent_activity]
    when 'expert_technique'
      [:validation_queue, :recent_documents, :recent_activity, :statistics]
    else
      [:recent_documents, :recent_activity, :statistics]
    end
  end

  def calculate_recent_documents_data
    documents = Document.joins(:space)
                       .where(spaces: { organization: @organization })
                       .where('documents.created_at > ?', 7.days.ago)
                       .includes(:uploaded_by, :tags, :file_attachment)
                       .order(created_at: :desc)
                       .limit(10)

    {
      documents: documents.map { |doc| serialize_document(doc) },
      total_count: documents.count,
      this_week_count: documents.where('created_at > ?', 1.week.ago).count,
      last_updated: Time.current
    }
  end

  def calculate_pending_documents_data
    base_scope = Document.joins(:space)
                        .where(spaces: { organization: @organization })

    pending_docs = case @profile_type
                   when 'direction'
                     base_scope.where(status: ['draft', 'under_review'])
                   when 'chef_projet'
                     # Documents in user's projects or uploaded by user
                     project_docs = base_scope.where(documentable_type: 'Immo::Promo::Project')
                                             .joins("LEFT JOIN immo_promo_projects ON documents.documentable_id = immo_promo_projects.id")
                                             .where('immo_promo_projects.project_manager_id = ? OR documents.uploaded_by_id = ?', @user.id, @user.id)
                     project_docs.where(status: ['draft', 'under_review'])
                   else
                     base_scope.where(uploaded_by: @user, status: ['draft', 'under_review'])
                   end

    {
      documents: pending_docs.includes(:uploaded_by, :tags).limit(8).map { |doc| serialize_document(doc) },
      total_count: pending_docs.count,
      urgent_count: pending_docs.joins(:validation_requests)
                               .where(validation_requests: { priority: 'high', status: 'pending' })
                               .count,
      overdue_count: pending_docs.joins(:validation_requests)
                                .where('validation_requests.due_date < ? AND validation_requests.status = ?', Date.current, 'pending')
                                .count
    }
  end

  def calculate_project_documents_data
    return {} unless defined?(Immo::Promo::Project)

    projects = case @profile_type
               when 'direction'
                 Immo::Promo::Project.where(organization: @organization).active
               when 'chef_projet'
                 Immo::Promo::Project.where(project_manager: @user).active
               when 'commercial'
                 user_stakeholder_projects = Immo::Promo::Stakeholder
                                           .where(user: @user, role: ['sales', 'marketing'])
                                           .joins(:project)
                                           .select('immo_promo_projects.*')
                 Immo::Promo::Project.where(id: user_stakeholder_projects.select(:project_id)).active
               else
                 Immo::Promo::Project.none
               end

    projects_data = projects.includes(:documents, :phases).limit(6).map do |project|
      {
        id: project.id,
        name: project.name,
        status: project.status,
        documents_count: project.documents.count,
        pending_documents: project.documents.where(status: ['draft', 'under_review']).count,
        recent_documents: project.documents.where('created_at > ?', 3.days.ago).count,
        completion_percentage: project.completion_percentage,
        urgent: project.documents.joins(:validation_requests)
                       .where(validation_requests: { priority: 'high', status: 'pending' })
                       .exists?
      }
    end

    {
      projects: projects_data,
      total_projects: projects.count,
      total_documents: projects.joins(:documents).count,
      pending_documents: projects.joins(:documents).where(documents: { status: ['draft', 'under_review'] }).count
    }
  end

  def calculate_validation_queue_data
    validations = ValidationRequest.joins(validatable: :space)
                                  .where(spaces: { organization: @organization })
                                  .where(status: 'pending')

    # Filter by profile
    validations = case @profile_type
                  when 'direction'
                    validations.where(assigned_to: @user)
                           .or(validations.joins(:assigned_to).where(users: { organization: @organization }))
                  when 'juriste'
                    validations.where(assigned_to: @user)
                           .or(validations.joins(:validatable).where(documents: { document_category: ['legal', 'permit'] }))
                  when 'expert_technique'
                    validations.where(assigned_to: @user)
                           .or(validations.joins(:validatable).where(documents: { document_category: ['technical', 'plan'] }))
                  else
                    validations.where(assigned_to: @user)
                  end

    {
      validations: validations.includes(:validatable, :requester).limit(10).map { |val| serialize_validation(val) },
      total_count: validations.count,
      high_priority: validations.where(priority: 'high').count,
      overdue: validations.where('due_date < ?', Date.current).count,
      due_today: validations.where(due_date: Date.current).count
    }
  end

  def calculate_compliance_alerts_data
    return {} unless defined?(Immo::Promo::Project)

    alerts = []
    projects = case @profile_type
               when 'direction'
                 Immo::Promo::Project.where(organization: @organization).active
               when 'chef_projet'
                 Immo::Promo::Project.where(project_manager: @user).active
               else
                 Immo::Promo::Project.none
               end

    projects.includes(:documents, :phases, :permits).each do |project|
      # Missing critical documents
      missing_docs = project.missing_critical_documents
      if missing_docs.any?
        alerts << {
          type: 'missing_documents',
          severity: 'high',
          project_id: project.id,
          project_name: project.name,
          message: "Documents manquants: #{missing_docs.join(', ')}",
          count: missing_docs.count
        }
      end

      # Overdue phases
      overdue_phases = project.phases.where('end_date < ? AND status != ?', Date.current, 'completed')
      if overdue_phases.any?
        alerts << {
          type: 'overdue_phases',
          severity: 'high',
          project_id: project.id,
          project_name: project.name,
          message: "#{overdue_phases.count} phase(s) en retard",
          count: overdue_phases.count
        }
      end

      # Expiring permits
      expiring_permits = project.permits.where(
        expiry_date: Date.current..30.days.from_now,
        status: 'approved'
      )
      if expiring_permits.any?
        alerts << {
          type: 'expiring_permits',
          severity: 'medium',
          project_id: project.id,
          project_name: project.name,
          message: "#{expiring_permits.count} permis expirant sous 30j",
          count: expiring_permits.count
        }
      end
    end

    {
      alerts: alerts.sort_by { |a| [a[:severity] == 'high' ? 0 : 1, a[:project_name]] }.first(10),
      total_count: alerts.count,
      high_severity: alerts.count { |a| a[:severity] == 'high' },
      medium_severity: alerts.count { |a| a[:severity] == 'medium' }
    }
  end

  def calculate_recent_activity_data
    activities = []

    # Recent document uploads
    recent_docs = Document.joins(:space)
                         .where(spaces: { organization: @organization })
                         .where('documents.created_at > ?', 1.week.ago)
                         .includes(:uploaded_by)
                         .order(created_at: :desc)
                         .limit(15)

    recent_docs.each do |doc|
      activities << {
        type: 'document_upload',
        timestamp: doc.created_at,
        title: "Document ajouté: #{doc.title}",
        user: doc.uploaded_by.full_name,
        icon: 'document',
        link: "/ged/documents/#{doc.id}"
      }
    end

    # Recent validations
    recent_validations = ValidationRequest.joins(validatable: :space)
                                         .where(spaces: { organization: @organization })
                                         .where('validation_requests.updated_at > ?', 1.week.ago)
                                         .where.not(status: 'pending')
                                         .includes(:validatable, :assigned_to)
                                         .order(updated_at: :desc)
                                         .limit(10)

    recent_validations.each do |validation|
      activities << {
        type: 'validation',
        timestamp: validation.updated_at,
        title: "Document #{validation.status == 'approved' ? 'approuvé' : 'rejeté'}: #{validation.validatable.title}",
        user: validation.assigned_to.full_name,
        icon: validation.status == 'approved' ? 'check-circle' : 'x-circle',
        link: "/ged/documents/#{validation.validatable.id}"
      }
    end

    # Recent project updates (if ImmoPromo available)
    if defined?(Immo::Promo::Project)
      recent_projects = Immo::Promo::Project.where(organization: @organization)
                                           .where('updated_at > ?', 1.week.ago)
                                           .order(updated_at: :desc)
                                           .limit(5)

      recent_projects.each do |project|
        activities << {
          type: 'project_update',
          timestamp: project.updated_at,
          title: "Projet mis à jour: #{project.name}",
          user: project.project_manager&.full_name || 'Système',
          icon: 'building',
          link: "/immo/promo/projects/#{project.id}"
        }
      end
    end

    sorted_activities = activities.sort_by { |a| a[:timestamp] }.reverse.first(12)

    {
      activities: sorted_activities,
      total_count: sorted_activities.count,
      last_updated: Time.current
    }
  end

  def calculate_statistics_data
    base_documents = Document.joins(:space).where(spaces: { organization: @organization })
    
    {
      total_documents: base_documents.count,
      this_month: base_documents.where('created_at > ?', 1.month.ago).count,
      this_week: base_documents.where('created_at > ?', 1.week.ago).count,
      pending_validations: ValidationRequest.joins(validatable: :space)
                                           .where(spaces: { organization: @organization })
                                           .where(status: 'pending')
                                           .count,
      approved_this_week: ValidationRequest.joins(validatable: :space)
                                          .where(spaces: { organization: @organization })
                                          .where(status: 'approved', updated_at: 1.week.ago..Time.current)
                                          .count,
      storage_used: base_documents.joins(file_attachment: :blob).sum('active_storage_blobs.byte_size'),
      by_category: base_documents.group(:document_category).count,
      by_status: base_documents.group(:status).count
    }
  end

  def serialize_document(document)
    {
      id: document.id,
      title: document.title,
      category: document.document_category,
      status: document.status,
      uploaded_by: document.uploaded_by.full_name,
      created_at: document.created_at,
      file_size: document.file.attached? ? document.file.byte_size : 0,
      tags: document.tags.pluck(:name)
    }
  end

  def serialize_validation(validation)
    {
      id: validation.id,
      document_title: validation.validatable.title,
      document_id: validation.validatable.id,
      requester: validation.requester.full_name,
      priority: validation.priority,
      due_date: validation.due_date,
      created_at: validation.created_at,
      notes: validation.notes
    }
  end
end