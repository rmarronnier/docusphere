class SearchController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_policy_scoped, only: [:index, :suggestions]
  skip_after_action :verify_authorized, only: [:index, :suggestions]

  def index
    @query = params[:q]
    
    if @query.present?
      @documents = policy_scope(Document)
        .where("documents.title ILIKE ? OR documents.description ILIKE ? OR documents.content ILIKE ?", 
               "%#{@query}%", "%#{@query}%", "%#{@query}%")
        .includes(:tags, :metadata, :user, :space)
        .order(updated_at: :desc)
        .page(params[:page])
    else
      @documents = Document.none.page(params[:page])
    end
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
end