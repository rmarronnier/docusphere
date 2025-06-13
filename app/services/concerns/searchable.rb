# Concern for services that handle search functionality
module Searchable
  extend ActiveSupport::Concern

  included do
    attr_reader :search_params, :search_results, :search_metadata
  end

  # Build search query from parameters
  def build_search_query(params = {})
    @search_params = sanitize_search_params(params)
    
    query = base_query
    query = apply_text_search(query) if @search_params[:q].present?
    query = apply_filters(query)
    query = apply_sorting(query)
    query = apply_pagination(query)
    
    query
  end

  # Execute search with results and metadata
  def execute_search(params = {})
    query = build_search_query(params)
    
    @search_results = query
    @search_metadata = build_search_metadata
    
    {
      results: @search_results,
      metadata: @search_metadata
    }
  end

  # Build search suggestions
  def search_suggestions(term, limit: 10)
    return [] if term.blank? || term.length < 2
    
    suggestions = []
    
    # Add recent searches
    suggestions += recent_searches(term, limit: limit / 2)
    
    # Add auto-complete suggestions
    suggestions += auto_complete_suggestions(term, limit: limit / 2)
    
    suggestions.uniq.take(limit)
  end

  # Advanced search with multiple criteria
  def advanced_search(criteria = {})
    query = base_query
    
    criteria.each do |field, value|
      next if value.blank?
      
      query = apply_field_filter(query, field, value)
    end
    
    @search_results = query
    @search_metadata = build_search_metadata
    
    {
      results: @search_results,
      metadata: @search_metadata,
      criteria: criteria
    }
  end

  # Search with facets for filtering
  def faceted_search(params = {})
    base_results = execute_search(params)
    facets = build_facets
    
    base_results.merge(facets: facets)
  end

  # Export search results
  def export_search_results(format: :csv, params: {})
    search_data = execute_search(params)
    
    case format.to_sym
    when :csv
      export_to_csv(search_data[:results])
    when :excel
      export_to_excel(search_data[:results])
    when :json
      search_data.to_json
    else
      search_data
    end
  end

  private

  # To be implemented by including services
  def base_query
    raise NotImplementedError, "Services must implement base_query"
  end

  def sanitize_search_params(params)
    {
      q: params[:q]&.strip,
      page: (params[:page] || 1).to_i,
      per_page: [(params[:per_page] || 25).to_i, 100].min,
      sort: params[:sort]&.to_sym,
      direction: params[:direction]&.downcase == 'desc' ? :desc : :asc,
      filters: params[:filters] || {}
    }
  end

  def apply_text_search(query)
    search_term = @search_params[:q]
    
    # Basic text search - to be customized by implementing services
    if query.respond_to?(:where)
      searchable_fields.reduce(query.none) do |accumulated_query, field|
        field_query = query.where("#{field} ILIKE ?", "%#{search_term}%")
        accumulated_query.or(field_query)
      end
    else
      query
    end
  end

  def apply_filters(query)
    @search_params[:filters].each do |key, value|
      next if value.blank?
      
      query = apply_field_filter(query, key, value)
    end
    
    query
  end

  def apply_field_filter(query, field, value)
    return query unless query.respond_to?(:where)
    
    case value
    when Array
      query.where(field => value)
    when Range
      query.where(field => value)
    when Hash
      # Handle date ranges, numeric ranges, etc.
      if value[:from] || value[:to]
        query = query.where("#{field} >= ?", value[:from]) if value[:from]
        query = query.where("#{field} <= ?", value[:to]) if value[:to]
      end
      query
    else
      query.where(field => value)
    end
  end

  def apply_sorting(query)
    return query unless query.respond_to?(:order)
    
    sort_field = @search_params[:sort] || default_sort_field
    direction = @search_params[:direction]
    
    if valid_sort_field?(sort_field)
      query.order(sort_field => direction)
    else
      query.order(default_sort_field => :desc)
    end
  end

  def apply_pagination(query)
    return query unless query.respond_to?(:page)
    
    if defined?(Kaminari) && query.respond_to?(:page)
      query.page(@search_params[:page]).per(@search_params[:per_page])
    else
      query.limit(@search_params[:per_page]).offset((@search_params[:page] - 1) * @search_params[:per_page])
    end
  end

  def build_search_metadata
    return {} unless @search_results
    
    metadata = {
      total_count: total_count,
      page: @search_params[:page],
      per_page: @search_params[:per_page],
      total_pages: total_pages,
      search_time: search_execution_time
    }
    
    # Add facet counts if available
    if respond_to?(:facet_counts, true)
      metadata[:facets] = facet_counts
    end
    
    metadata
  end

  def build_facets
    return {} unless @search_results
    
    # Basic facet implementation - to be customized
    {}
  end

  def total_count
    if @search_results.respond_to?(:total_count)
      @search_results.total_count
    elsif @search_results.respond_to?(:count)
      @search_results.count
    else
      0
    end
  end

  def total_pages
    return 1 if total_count.zero?
    (total_count.to_f / @search_params[:per_page]).ceil
  end

  def search_execution_time
    # Would be measured in real implementation
    nil
  end

  def searchable_fields
    # Default searchable fields - to be overridden
    [:name, :title, :description]
  end

  def default_sort_field
    :created_at
  end

  def valid_sort_field?(field)
    # Define valid sort fields in implementing services
    [:created_at, :updated_at, :name, :title].include?(field)
  end

  def recent_searches(term, limit: 5)
    # Would query recent searches from cache or database
    []
  end

  def auto_complete_suggestions(term, limit: 5)
    # Would generate suggestions based on existing data
    []
  end

  def export_to_csv(results)
    require 'csv'
    
    return CSV.generate if results.empty?
    
    headers = results.first.respond_to?(:attributes) ? results.first.attributes.keys : []
    
    CSV.generate(headers: true) do |csv|
      csv << headers.map(&:humanize) unless headers.empty?
      
      results.each do |result|
        if result.respond_to?(:attributes)
          csv << result.attributes.values
        elsif result.is_a?(Hash)
          csv << result.values
        end
      end
    end
  end

  def export_to_excel(results)
    require 'axlsx'
    
    package = Axlsx::Package.new
    workbook = package.workbook
    
    workbook.add_worksheet(name: "Search Results") do |sheet|
      if results.present?
        # Add headers
        if results.first.respond_to?(:attributes)
          headers = results.first.attributes.keys.map(&:humanize)
          sheet.add_row headers, style: sheet.styles.add_style(b: true)
          
          # Add data
          results.each do |result|
            sheet.add_row result.attributes.values
          end
        end
      end
    end
    
    package.to_stream.read
  end
end