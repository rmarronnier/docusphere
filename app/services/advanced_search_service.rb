# frozen_string_literal: true

class AdvancedSearchService
  include Searchable
  include ActionView::Helpers::TextHelper

  def initialize(user, search_params = {})
    @user = user
    @organization = user.organization
    @search_params = sanitize_search_params(search_params.with_indifferent_access)
  end

  # Execute advanced search using Searchable concern
  def search
    search_result = execute_search(@search_params)
    
    # Enhance with document-specific metadata
    search_result.merge(
      suggestions: generate_suggestions,
      user_searches: recent_user_searches
    )
  end

  # Document-specific autocomplete
  def autocomplete_suggestions(query, limit: 10)
    search_suggestions(query, limit: limit)
  end

  # Save search for reuse
  def save_search(name = nil)
    return unless @user && @search_params.present?

    search_name = name || generate_search_name
    
    SearchQuery.create!(
      user: @user,
      organization: @organization,
      name: search_name,
      query_params: @search_params.to_json,
      search_type: 'advanced',
      description: generate_search_description
    )
  end

  # Export search results in various formats
  def export_results(format: :csv)
    export_search_results(format: format, params: @search_params)
  end

  # Get user's saved searches
  def saved_searches
    return [] unless @user
    
    @user.search_queries
         .where(search_type: 'advanced')
         .recent
         .limit(10)
         .includes(:user)
  end

  # Execute saved search
  def execute_saved_search(search_query_id)
    saved_search = @user.search_queries.find(search_query_id)
    saved_params = JSON.parse(saved_search.query_params).with_indifferent_access
    
    # Update search params and execute
    @search_params = sanitize_search_params(saved_params)
    search
  end

  private

  # Override base_query from Searchable concern
  def base_query
    Document.joins(:space)
            .where(spaces: { organization: @organization })
            .accessible_by(@user)
  end

  # Override searchable_fields from Searchable concern
  def searchable_fields
    [:title, :description, :content, :file_name]
  end

  # Override apply_text_search to include content search
  def apply_text_search(query)
    return query unless @search_params[:q].present?
    
    search_term = @search_params[:q]
    
    # Full-text search across multiple fields
    query.where(
      "title ILIKE :term OR description ILIKE :term OR content ILIKE :term OR file_name ILIKE :term",
      term: "%#{search_term}%"
    )
  end

  # Override apply_filters to add document-specific filters
  def apply_filters(query)
    query = super(query) # Apply base filters
    
    # Document-specific filters
    query = apply_category_filter(query)
    query = apply_size_filter(query)
    query = apply_user_filters(query)
    query = apply_tag_filter(query)
    query = apply_project_filter(query)
    query = apply_validation_filter(query)
    query = apply_content_type_filter(query)
    query = apply_metadata_filters(query)
    
    query
  end

  def apply_category_filter(query)
    return query unless @search_params[:filters][:category].present?
    
    category = @search_params[:filters][:category]
    query.where(category: category)
  end

  def apply_size_filter(query)
    return query unless @search_params[:filters][:size_range].present?
    
    size_range = @search_params[:filters][:size_range]
    case size_range
    when 'small'
      query.where('file_size < ?', 1.megabyte)
    when 'medium' 
      query.where('file_size BETWEEN ? AND ?', 1.megabyte, 10.megabytes)
    when 'large'
      query.where('file_size > ?', 10.megabytes)
    else
      query
    end
  end

  def apply_user_filters(query)
    filters = @search_params[:filters]
    
    if filters[:uploaded_by].present?
      query = query.joins(:uploaded_by).where(users: { id: filters[:uploaded_by] })
    end
    
    if filters[:last_modified_by].present?
      query = query.where(last_modified_by_id: filters[:last_modified_by])
    end
    
    query
  end

  def apply_tag_filter(query)
    return query unless @search_params[:filters][:tags].present?
    
    tag_names = Array(@search_params[:filters][:tags])
    query.joins(:tags).where(tags: { name: tag_names })
  end

  def apply_project_filter(query)
    return query unless @search_params[:filters][:project_id].present?
    return query unless defined?(Immo::Promo::Project)
    
    project_id = @search_params[:filters][:project_id]
    query.where(documentable_type: 'Immo::Promo::Project', documentable_id: project_id)
  end

  def apply_validation_filter(query)
    return query unless @search_params[:filters][:validation_status].present?
    
    status = @search_params[:filters][:validation_status]
    case status
    when 'pending'
      query.joins(:validation_requests).where(validation_requests: { status: 'pending' })
    when 'approved'
      query.joins(:validation_requests).where(validation_requests: { status: 'approved' })
    when 'rejected'
      query.joins(:validation_requests).where(validation_requests: { status: 'rejected' })
    when 'none'
      query.left_joins(:validation_requests).where(validation_requests: { id: nil })
    else
      query
    end
  end

  def apply_content_type_filter(query)
    return query unless @search_params[:filters][:content_type].present?
    
    content_types = Array(@search_params[:filters][:content_type])
    query.joins(:file_attachment).where(active_storage_blobs: { content_type: content_types })
  end

  def apply_metadata_filters(query)
    metadata_filters = @search_params[:filters][:metadata] || {}
    
    metadata_filters.each do |key, value|
      next if value.blank?
      
      query = query.joins(:metadata)
                   .where(metadata: { key: key, value: value })
    end
    
    query
  end

  # Override build_facets from Searchable concern
  def build_facets
    return {} unless @search_results
    
    base_query_for_facets = base_query
    base_query_for_facets = apply_text_search(base_query_for_facets)
    
    {
      categories: build_category_facets(base_query_for_facets),
      content_types: build_content_type_facets(base_query_for_facets),
      size_ranges: build_size_facets(base_query_for_facets),
      users: build_user_facets(base_query_for_facets),
      tags: build_tag_facets(base_query_for_facets),
      projects: build_project_facets(base_query_for_facets),
      validation_status: build_validation_facets(base_query_for_facets)
    }
  end

  def build_category_facets(query)
    query.group(:category).count
  end

  def build_content_type_facets(query)
    query.joins(:file_attachment)
         .group('active_storage_blobs.content_type')
         .count
         .transform_keys { |ct| content_type_label(ct) }
  end

  def build_size_facets(query)
    {
      'Petit (< 1MB)' => query.where('file_size < ?', 1.megabyte).count,
      'Moyen (1-10MB)' => query.where('file_size BETWEEN ? AND ?', 1.megabyte, 10.megabytes).count,
      'Grand (> 10MB)' => query.where('file_size > ?', 10.megabytes).count
    }
  end

  def build_user_facets(query)
    query.joins(:uploaded_by)
         .group('users.full_name')
         .count
         .first(10) # Limit to top 10 users
         .to_h
  end

  def build_tag_facets(query)
    query.joins(:tags)
         .group('tags.name')
         .count
         .first(20) # Limit to top 20 tags
         .to_h
  end

  def build_project_facets(query)
    return {} unless defined?(Immo::Promo::Project)
    
    query.joins("LEFT JOIN immo_promo_projects ON documents.documentable_type = 'Immo::Promo::Project' AND documents.documentable_id = immo_promo_projects.id")
         .group('immo_promo_projects.name')
         .count
         .compact
         .first(10)
         .to_h
  end

  def build_validation_facets(query)
    {
      'En attente' => query.joins(:validation_requests).where(validation_requests: { status: 'pending' }).count,
      'Approuvé' => query.joins(:validation_requests).where(validation_requests: { status: 'approved' }).count,
      'Rejeté' => query.joins(:validation_requests).where(validation_requests: { status: 'rejected' }).count,
      'Aucune' => query.left_joins(:validation_requests).where(validation_requests: { id: nil }).count
    }
  end

  # Override recent_searches from Searchable concern
  def recent_searches(term, limit: 5)
    return [] unless @user
    
    @user.search_queries
         .where("name ILIKE ? OR query_params ILIKE ?", "%#{term}%", "%#{term}%")
         .recent
         .limit(limit)
         .pluck(:name)
  end

  # Override auto_complete_suggestions from Searchable concern
  def auto_complete_suggestions(term, limit: 5)
    suggestions = []
    
    # Document titles
    title_suggestions = base_query.where("title ILIKE ?", "%#{term}%")
                                 .limit(limit / 2)
                                 .pluck(:title)
                                 .map { |title| { type: 'document', value: title, icon: 'document' } }
    suggestions.concat(title_suggestions)
    
    # Tags
    tag_suggestions = Tag.where(organization: @organization)
                        .where("name ILIKE ?", "%#{term}%")
                        .limit(limit / 2)
                        .pluck(:name)
                        .map { |tag| { type: 'tag', value: tag, icon: 'tag' } }
    suggestions.concat(tag_suggestions)
    
    suggestions.first(limit)
  end

  def generate_search_name
    parts = []
    
    parts << "\"#{@search_params[:q]}\"" if @search_params[:q].present?
    
    filters = @search_params[:filters] || {}
    parts << "Catégorie: #{filters[:category]}" if filters[:category].present?
    parts << "Taille: #{filters[:size_range]}" if filters[:size_range].present?
    parts << "Tags: #{Array(filters[:tags]).join(', ')}" if filters[:tags].present?
    
    if parts.empty?
      "Recherche #{Time.current.strftime('%d/%m/%Y %H:%M')}"
    else
      parts.join(' • ')
    end
  end

  def generate_search_description
    filter_count = (@search_params[:filters]&.size || 0)
    text_search = @search_params[:q].present? ? 'avec texte' : 'sans texte'
    
    "Recherche avancée #{text_search}, #{filter_count} filtre(s) appliqué(s)"
  end

  def recent_user_searches
    return [] unless @user
    
    @user.search_queries.recent.limit(5).includes(:user)
  end

  def content_type_label(content_type)
    case content_type
    when 'application/pdf' then 'PDF'
    when /image/ then 'Images'
    when /video/ then 'Vidéos'
    when /audio/ then 'Audio'
    when /text/ then 'Texte'
    when /application\/vnd\.ms/ then 'Microsoft Office'
    when /application\/vnd\.openxmlformats/ then 'Office (OOXML)'
    else content_type.split('/').last.upcase
    end
  end
end