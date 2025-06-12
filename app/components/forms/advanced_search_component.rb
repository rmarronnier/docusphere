# frozen_string_literal: true

module Forms
  class AdvancedSearchComponent < ViewComponent::Base
    def initialize(user:, search_params: {}, show_saved_searches: true)
      @user = user
      @search_params = search_params.with_indifferent_access
      @show_saved_searches = show_saved_searches
      @search_service = AdvancedSearchService.new(@user, @search_params)
    end

    private

    attr_reader :user, :search_params, :show_saved_searches, :search_service

    def category_options
      Document.distinct.where.not(document_category: nil)
              .joins(:space)
              .where(spaces: { organization: user.organization })
              .pluck(:document_category)
              .compact
              .sort
              .map { |cat| [cat.humanize, cat] }
    end

    def status_options
      [
        ['Brouillon', 'draft'],
        ['Publié', 'published'],
        ['En révision', 'under_review'],
        ['Verrouillé', 'locked'],
        ['Archivé', 'archived']
      ]
    end

    def date_range_options
      [
        ['Aujourd\'hui', 'today'],
        ['Hier', 'yesterday'],
        ['Cette semaine', 'this_week'],
        ['Ce mois', 'this_month'],
        ['Cette année', 'this_year'],
        ['Personnalisé', 'custom']
      ]
    end

    def date_field_options
      [
        ['Date de création', 'created_at'],
        ['Date de modification', 'updated_at'],
        ['Date d\'upload', 'uploaded_at']
      ]
    end

    def validation_status_options
      [
        ['En attente de validation', 'pending'],
        ['Approuvé', 'approved'],
        ['Rejeté', 'rejected'],
        ['Jamais validé', 'never_validated']
      ]
    end

    def content_type_options
      [
        ['PDF', 'application/pdf'],
        ['Images', 'image/*'],
        ['Documents Word', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
        ['Documents Excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
        ['Présentations PowerPoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'],
        ['Fichiers texte', 'text/plain'],
        ['Archives ZIP', 'application/zip'],
        ['Vidéos', 'video/*'],
        ['Audio', 'audio/*']
      ]
    end

    def sort_options
      [
        ['Plus récent', 'created_at'],
        ['Titre', 'title'],
        ['Taille', 'size'],
        ['Dernière modification', 'updated_at'],
        ['Pertinence', 'relevance']
      ]
    end

    def sort_order_options
      [
        ['Croissant', 'asc'],
        ['Décroissant', 'desc']
      ]
    end

    def available_users
      User.where(organization: user.organization)
          .joins(:uploaded_documents)
          .distinct
          .order(:full_name)
          .pluck(:full_name, :id)
    end

    def available_projects
      return [] unless defined?(Immo::Promo::Project)

      case user.active_profile&.profile_type
      when 'direction'
        Immo::Promo::Project.where(organization: user.organization)
      when 'chef_projet'
        Immo::Promo::Project.where(project_manager: user)
      when 'commercial'
        user_stakeholder_projects = Immo::Promo::Stakeholder
                                   .where(user: user, role: ['sales', 'marketing'])
                                   .joins(:project)
                                   .select('immo_promo_projects.*')
        Immo::Promo::Project.where(id: user_stakeholder_projects.select(:project_id))
      else
        Immo::Promo::Project.none
      end.active.order(:name).pluck(:name, :id)
    end

    def saved_searches
      @saved_searches ||= search_service.saved_searches
    end

    def popular_tags
      Tag.joins(:document_tags)
         .joins("JOIN documents ON document_tags.document_id = documents.id")
         .joins("JOIN spaces ON documents.space_id = spaces.id")
         .where(spaces: { organization: user.organization })
         .group('tags.name')
         .order('COUNT(*) DESC')
         .limit(20)
         .pluck('tags.name', 'COUNT(*)')
         .map { |name, count| { name: name, count: count } }
    end

    def selected_categories
      Array(search_params[:categories])
    end

    def selected_statuses
      Array(search_params[:statuses])
    end

    def selected_tags
      Array(search_params[:tags])
    end

    def selected_content_types
      Array(search_params[:content_types])
    end

    def selected_projects
      Array(search_params[:project_ids])
    end

    def selected_users
      Array(search_params[:uploaded_by])
    end

    def show_custom_date_fields?
      search_params[:date_range] == 'custom'
    end

    def size_min_display
      size_min = search_params[:size_min]
      return '' if size_min.blank?
      
      size_min_bytes = parse_size_to_bytes(size_min)
      return size_min if size_min_bytes.nil?
      
      number_to_human_size(size_min_bytes)
    end

    def size_max_display
      size_max = search_params[:size_max]
      return '' if size_max.blank?
      
      size_max_bytes = parse_size_to_bytes(size_max)
      return size_max if size_max_bytes.nil?
      
      number_to_human_size(size_max_bytes)
    end

    def active_filters_count
      filters = search_params.reject { |k, v| v.blank? || k.in?(['sort_by', 'sort_order']) }
      filters.count
    end

    def has_active_filters?
      active_filters_count > 0
    end

    def clear_filters_url
      url_for(params.permit.except(:search))
    end

    def autocomplete_url
      search_suggestions_path
    end

    def form_id
      'advanced-search-form'
    end

    def stimulus_controllers
      [
        'advanced-search',
        'tag-selector',
        'date-picker',
        'autocomplete'
      ].join(' ')
    end

    private

    def parse_size_to_bytes(size_string)
      return nil if size_string.blank?

      case size_string.downcase
      when /(\d+)\s*kb?$/
        $1.to_i * 1.kilobyte
      when /(\d+)\s*mb?$/
        $1.to_i * 1.megabyte
      when /(\d+)\s*gb?$/
        $1.to_i * 1.gigabyte
      when /^\d+$/
        size_string.to_i
      else
        nil
      end
    end
  end
end