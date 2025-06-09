class SearchController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_policy_scoped, only: [:index, :suggestions]
  skip_after_action :verify_authorized, only: [:index, :suggestions]

  def index
    @query = params[:q]
    @advanced_search = params[:advanced].present?
    
    if @query.present? || @advanced_search
      @documents = build_search_query
      @documents = @documents.page(params[:page])
    else
      @documents = Document.none.page(params[:page])
    end
    
    # For advanced search filters
    @spaces = policy_scope(Space).order(:name)
    @users = User.where(organization: current_user.organization).order(:last_name, :first_name)
    @tags = Tag.where(organization: current_user.organization).order(:name)
  end
  
  def advanced
    @spaces = policy_scope(Space).order(:name)
    @users = User.where(organization: current_user.organization).order(:last_name, :first_name)
    @tags = Tag.where(organization: current_user.organization).order(:name)
  end
  
  def suggestions
    query = params[:q]
    
    if query.present? && query.length >= 2
      documents = policy_scope(Document)
        .where("documents.title ILIKE ? OR documents.description ILIKE ?", "%#{query}%", "%#{query}%")
        .limit(10)
      
      # Recherche dans les métadonnées
      metadata_docs = policy_scope(Document)
        .joins(:metadata)
        .where("metadata.value ILIKE ?", "%#{query}%")
        .limit(5)
      
      # Recherche dans les tags
      tag_docs = policy_scope(Document)
        .joins(:tags)
        .where("tags.name ILIKE ?", "%#{query}%")
        .limit(5)
      
      # Combiner et dédupliquer les résultats
      all_docs = (documents + metadata_docs + tag_docs).uniq.first(10)
      
      suggestions = all_docs.map do |doc|
        {
          id: doc.id,
          title: doc.title,
          description: doc.description&.truncate(100),
          type: doc.document_type,
          space: doc.space.name,
          url: ged_document_path(doc)
        }
      end
      
      render json: { suggestions: suggestions }
    else
      render json: { suggestions: [] }
    end
  end
  
  private
  
  def build_search_query
    documents = policy_scope(Document)
      .includes(:tags, :metadata, :uploaded_by, :space)
    
    # Basic text search
    if @query.present?
      documents = documents.where(
        "documents.title ILIKE ? OR documents.description ILIKE ? OR documents.content ILIKE ?", 
        "%#{@query}%", "%#{@query}%", "%#{@query}%"
      )
    end
    
    # Advanced filters
    if params[:space_id].present?
      documents = documents.where(space_id: params[:space_id])
    end
    
    if params[:uploaded_by_id].present?
      documents = documents.where(uploaded_by_id: params[:uploaded_by_id])
    end
    
    if params[:tag_ids].present?
      documents = documents.joins(:document_tags)
        .where(document_tags: { tag_id: params[:tag_ids] })
        .distinct
    end
    
    if params[:date_from].present?
      documents = documents.where("documents.created_at >= ?", params[:date_from])
    end
    
    if params[:date_to].present?
      documents = documents.where("documents.created_at <= ?", params[:date_to])
    end
    
    if params[:file_type].present?
      case params[:file_type]
      when 'pdf'
        documents = documents.joins(:file_attachment)
          .where("active_storage_blobs.content_type = ?", 'application/pdf')
      when 'word'
        documents = documents.joins(:file_attachment)
          .where("active_storage_blobs.content_type IN (?)", 
            ['application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
      when 'excel'
        documents = documents.joins(:file_attachment)
          .where("active_storage_blobs.content_type IN (?)", 
            ['application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
      when 'image'
        documents = documents.joins(:file_attachment)
          .where("active_storage_blobs.content_type LIKE ?", 'image/%')
      end
    end
    
    if params[:status].present?
      documents = documents.where(status: params[:status])
    end
    
    # Sorting
    case params[:sort_by]
    when 'title'
      documents = documents.order(:title)
    when 'created_at_asc'
      documents = documents.order(created_at: :asc)
    when 'size'
      documents = documents.joins(:file_attachment)
        .order('active_storage_blobs.byte_size DESC')
    else
      documents = documents.order(updated_at: :desc)
    end
    
    documents
  end
end