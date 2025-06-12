# frozen_string_literal: true

class AdvancedSearchService
  include ActionView::Helpers::TextHelper

  def initialize(user, search_params = {})
    @user = user
    @organization = user.organization
    @search_params = search_params.with_indifferent_access
    @base_scope = build_base_scope
  end

  # Execute advanced search with multiple criteria
  def search
    scope = @base_scope
    
    # Apply search filters in order of performance impact
    scope = apply_text_search(scope)
    scope = apply_category_filter(scope)
    scope = apply_status_filter(scope)
    scope = apply_date_filters(scope)
    scope = apply_size_filter(scope)
    scope = apply_user_filters(scope)
    scope = apply_tag_filter(scope)
    scope = apply_project_filter(scope)
    scope = apply_validation_filter(scope)
    scope = apply_content_type_filter(scope)
    scope = apply_metadata_filters(scope)
    
    # Apply sorting
    scope = apply_sorting(scope)
    
    # Return paginated results with metadata
    {
      documents: scope.includes(:uploaded_by, :tags, :file_attachment, :space, :folder),
      total_count: scope.count,
      facets: generate_facets(scope),
      search_metadata: generate_search_metadata,
      suggestions: generate_suggestions
    }
  end

  # Get search suggestions based on user input
  def autocomplete_suggestions(query, limit: 10)
    return [] if query.blank? || query.length < 2

    suggestions = []

    # Document titles
    title_matches = @base_scope.where("title ILIKE ?", "%#{query}%")
                              .limit(limit / 2)
                              .pluck(:title)
                              .map { |title| { type: 'document', value: title, icon: 'document' } }
    
    suggestions.concat(title_matches)

    # Tags
    tag_matches = Tag.where(organization: @organization)
                    .where("name ILIKE ?", "%#{query}%")
                    .limit(limit / 4)
                    .pluck(:name)
                    .map { |tag| { type: 'tag', value: tag, icon: 'tag' } }
    
    suggestions.concat(tag_matches)

    # Users (for uploaded_by filter)
    user_matches = User.where(organization: @organization)
                      .where("full_name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
                      .limit(limit / 4)
                      .pluck(:full_name)
                      .map { |name| { type: 'user', value: name, icon: 'user' } }
    
    suggestions.concat(user_matches)

    # Project names (if ImmoPromo available)
    if defined?(Immo::Promo::Project)
      project_matches = Immo::Promo::Project.where(organization: @organization)
                                           .where("name ILIKE ?", "%#{query}%")
                                           .limit(limit / 4)
                                           .pluck(:name)
                                           .map { |name| { type: 'project', value: name, icon: 'building' } }
      
      suggestions.concat(project_matches)
    end

    suggestions.uniq { |s| s[:value] }.first(limit)
  end

  # Save search query for future reference
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

  # Get saved searches for user
  def saved_searches
    SearchQuery.where(user: @user, search_type: 'advanced')
              .order(created_at: :desc)
              .limit(10)
              .map do |search|
                {
                  id: search.id,
                  name: search.name,
                  description: search.description,
                  created_at: search.created_at,
                  params: JSON.parse(search.query_params)
                }
              end
  end

  # Export search results
  def export_results(format: 'csv')
    results = search
    documents = results[:documents]

    case format.to_s.downcase
    when 'csv'
      generate_csv_export(documents)
    when 'xlsx'
      generate_xlsx_export(documents)
    when 'pdf'
      generate_pdf_export(documents, results)
    else
      raise ArgumentError, "Unsupported export format: #{format}"
    end
  end

  private

  attr_reader :user, :organization, :search_params

  def build_base_scope
    Document.joins(:space)
            .where(spaces: { organization: @organization })
            .where(Pundit.policy_scope(@user, Document).where_values_hash)
  end

  def apply_text_search(scope)
    query = @search_params[:q]
    return scope if query.blank?

    # Enhanced text search with relevance scoring
    search_terms = query.split(/\s+/).map(&:strip).reject(&:blank?)
    
    conditions = []
    search_terms.each do |term|
      escaped_term = ActiveRecord::Base.connection.quote_string(term)
      conditions << "(
        documents.title ILIKE '%#{escaped_term}%' OR 
        documents.description ILIKE '%#{escaped_term}%' OR
        documents.content ILIKE '%#{escaped_term}%' OR
        EXISTS (
          SELECT 1 FROM tags 
          JOIN document_tags ON tags.id = document_tags.tag_id 
          WHERE document_tags.document_id = documents.id 
          AND tags.name ILIKE '%#{escaped_term}%'
        )
      )"
    end

    scope.where(conditions.join(' AND '))
  end

  def apply_category_filter(scope)
    categories = @search_params[:categories]
    return scope if categories.blank?

    categories = [categories] unless categories.is_a?(Array)
    scope.where(document_category: categories)
  end

  def apply_status_filter(scope)
    statuses = @search_params[:statuses]
    return scope if statuses.blank?

    statuses = [statuses] unless statuses.is_a?(Array)
    scope.where(status: statuses)
  end

  def apply_date_filters(scope)
    date_from = parse_date(@search_params[:date_from])
    date_to = parse_date(@search_params[:date_to])
    date_field = @search_params[:date_field] || 'created_at'

    scope = scope.where("documents.#{date_field} >= ?", date_from) if date_from
    scope = scope.where("documents.#{date_field} <= ?", date_to.end_of_day) if date_to

    # Predefined date ranges
    case @search_params[:date_range]
    when 'today'
      scope.where("documents.#{date_field} >= ?", Date.current.beginning_of_day)
    when 'yesterday'
      scope.where("documents.#{date_field}": 1.day.ago.all_day)
    when 'this_week'
      scope.where("documents.#{date_field} >= ?", 1.week.ago.beginning_of_week)
    when 'this_month'
      scope.where("documents.#{date_field} >= ?", 1.month.ago.beginning_of_month)
    when 'this_year'
      scope.where("documents.#{date_field} >= ?", 1.year.ago.beginning_of_year)
    else
      scope
    end
  end

  def apply_size_filter(scope)
    size_min = parse_size(@search_params[:size_min])
    size_max = parse_size(@search_params[:size_max])

    if size_min || size_max
      scope = scope.joins(file_attachment: :blob)
      
      scope = scope.where('active_storage_blobs.byte_size >= ?', size_min) if size_min
      scope = scope.where('active_storage_blobs.byte_size <= ?', size_max) if size_max
    end

    scope
  end

  def apply_user_filters(scope)
    # Uploaded by specific users
    if @search_params[:uploaded_by].present?
      user_ids = @search_params[:uploaded_by]
      user_ids = [user_ids] unless user_ids.is_a?(Array)
      scope = scope.where(uploaded_by_id: user_ids)
    end

    # Documents I can edit
    if @search_params[:editable_by_me] == 'true'
      scope = scope.joins(:authorizations)
                  .where(authorizations: { 
                    user: @user, 
                    permission_level: ['write', 'admin'] 
                  })
    end

    # Documents shared with me
    if @search_params[:shared_with_me] == 'true'
      scope = scope.joins(:document_shares)
                  .where(document_shares: { shared_with: @user })
    end

    scope
  end

  def apply_tag_filter(scope)
    tags = @search_params[:tags]
    return scope if tags.blank?

    tags = [tags] unless tags.is_a?(Array)
    tag_operator = @search_params[:tag_operator] || 'any' # 'any' or 'all'

    if tag_operator == 'all'
      # Documents must have ALL specified tags
      tags.each do |tag_name|
        scope = scope.joins(:tags).where(tags: { name: tag_name })
      end
    else
      # Documents must have ANY of the specified tags
      scope = scope.joins(:tags).where(tags: { name: tags })
    end

    scope.distinct
  end

  def apply_project_filter(scope)
    return scope unless defined?(Immo::Promo::Project)

    project_ids = @search_params[:project_ids]
    return scope if project_ids.blank?

    project_ids = [project_ids] unless project_ids.is_a?(Array)
    scope.where(documentable_type: 'Immo::Promo::Project', documentable_id: project_ids)
  end

  def apply_validation_filter(scope)
    validation_status = @search_params[:validation_status]
    return scope if validation_status.blank?

    case validation_status
    when 'pending'
      scope.joins(:validation_requests).where(validation_requests: { status: 'pending' })
    when 'approved'
      scope.joins(:validation_requests).where(validation_requests: { status: 'approved' })
    when 'rejected'
      scope.joins(:validation_requests).where(validation_requests: { status: 'rejected' })
    when 'never_validated'
      scope.left_joins(:validation_requests).where(validation_requests: { id: nil })
    else
      scope
    end.distinct
  end

  def apply_content_type_filter(scope)
    content_types = @search_params[:content_types]
    return scope if content_types.blank?

    content_types = [content_types] unless content_types.is_a?(Array)
    
    scope.joins(file_attachment: :blob)
         .where('active_storage_blobs.content_type': content_types)
  end

  def apply_metadata_filters(scope)
    metadata_filters = @search_params[:metadata]
    return scope if metadata_filters.blank?

    metadata_filters.each do |key, value|
      next if value.blank?
      
      scope = scope.joins(:metadata)
                  .where(metadata: { key: key, value: value })
    end

    scope.distinct
  end

  def apply_sorting(scope)
    sort_by = @search_params[:sort_by] || 'created_at'
    sort_order = @search_params[:sort_order] || 'desc'

    case sort_by
    when 'title'
      scope.order("documents.title #{sort_order}")
    when 'size'
      scope.joins(file_attachment: :blob)
           .order("active_storage_blobs.byte_size #{sort_order}")
    when 'updated_at'
      scope.order("documents.updated_at #{sort_order}")
    when 'relevance'
      # Custom relevance scoring based on search terms
      apply_relevance_sorting(scope)
    else
      scope.order("documents.created_at #{sort_order}")
    end
  end

  def apply_relevance_sorting(scope)
    query = @search_params[:q]
    return scope.order(created_at: :desc) if query.blank?

    # Simple relevance scoring - can be enhanced with full-text search
    scope.select('documents.*, (
      CASE 
        WHEN documents.title ILIKE ? THEN 100
        WHEN documents.description ILIKE ? THEN 50
        WHEN documents.content ILIKE ? THEN 25
        ELSE 1
      END
    ) AS relevance_score', "%#{query}%", "%#{query}%", "%#{query}%")
         .order('relevance_score DESC, documents.created_at DESC')
  end

  def generate_facets(scope)
    {
      categories: scope.group(:document_category).count,
      statuses: scope.group(:status).count,
      content_types: scope.joins(file_attachment: :blob)
                         .group('active_storage_blobs.content_type')
                         .count,
      upload_dates: scope.group_by_month(:created_at, last: 12).count,
      file_sizes: {
        small: scope.joins(file_attachment: :blob)
                   .where('active_storage_blobs.byte_size < ?', 1.megabyte)
                   .count,
        medium: scope.joins(file_attachment: :blob)
                    .where('active_storage_blobs.byte_size BETWEEN ? AND ?', 
                           1.megabyte, 10.megabytes)
                    .count,
        large: scope.joins(file_attachment: :blob)
                   .where('active_storage_blobs.byte_size > ?', 10.megabytes)
                   .count
      }
    }
  end

  def generate_search_metadata
    {
      search_params: @search_params,
      search_time: Time.current,
      user_profile: @user.active_profile&.profile_type,
      filters_applied: @search_params.keys.count,
      query_complexity: calculate_query_complexity
    }
  end

  def generate_suggestions
    suggestions = []
    
    # Suggest removing restrictive filters if no results
    if @search_params[:categories].present?
      suggestions << {
        type: 'expand_search',
        message: 'Essayez de supprimer le filtre par catégorie',
        action: @search_params.except(:categories)
      }
    end

    # Suggest related searches based on user history
    recent_searches = SearchQuery.where(user: @user)
                                .where('created_at > ?', 1.month.ago)
                                .order(created_at: :desc)
                                .limit(3)

    recent_searches.each do |search|
      suggestions << {
        type: 'recent_search',
        message: "Recherche récente: #{search.name}",
        action: JSON.parse(search.query_params)
      }
    end

    suggestions.first(5)
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end

  def parse_size(size_string)
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

  def calculate_query_complexity
    complexity = 0
    
    complexity += 1 if @search_params[:q].present?
    complexity += @search_params.count { |k, v| v.present? && k != :q }
    complexity += (@search_params[:tags]&.length || 0) if @search_params[:tags].is_a?(Array)
    
    case complexity
    when 0..2 then 'simple'
    when 3..5 then 'moderate'
    else 'complex'
    end
  end

  def generate_search_name
    parts = []
    
    parts << "\"#{@search_params[:q]}\"" if @search_params[:q].present?
    parts << "catégorie: #{@search_params[:categories]}" if @search_params[:categories].present?
    parts << "statut: #{@search_params[:statuses]}" if @search_params[:statuses].present?
    parts << "depuis: #{@search_params[:date_from]}" if @search_params[:date_from].present?
    
    name = parts.join(', ')
    name.present? ? "Recherche: #{name}" : "Recherche du #{Date.current.strftime('%d/%m/%Y')}"
  end

  def generate_search_description
    filters = []
    
    filters << "Texte: #{@search_params[:q]}" if @search_params[:q].present?
    filters << "Catégories: #{Array(@search_params[:categories]).join(', ')}" if @search_params[:categories].present?
    filters << "Tags: #{Array(@search_params[:tags]).join(', ')}" if @search_params[:tags].present?
    filters << "Période: #{@search_params[:date_from]} - #{@search_params[:date_to]}" if @search_params[:date_from].present?
    
    filters.present? ? filters.join(' | ') : 'Recherche sans critères'
  end

  def generate_csv_export(documents)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['Titre', 'Catégorie', 'Statut', 'Uploadé par', 'Date création', 'Taille', 'Tags']
      
      documents.each do |doc|
        csv << [
          doc.title,
          doc.document_category,
          doc.status,
          doc.uploaded_by.full_name,
          doc.created_at.strftime('%d/%m/%Y %H:%M'),
          doc.file.attached? ? number_to_human_size(doc.file.byte_size) : 'N/A',
          doc.tags.pluck(:name).join(', ')
        ]
      end
    end
  end

  def generate_xlsx_export(documents)
    # Implementation would use Axlsx or similar gem
    "XLSX export not implemented yet"
  end

  def generate_pdf_export(documents, search_results)
    # Implementation would use Prawn or similar gem
    "PDF export not implemented yet"
  end
end