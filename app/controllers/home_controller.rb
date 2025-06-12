class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
  def index
    if user_signed_in?
      @pending_documents = load_pending_documents
      @recent_activities = load_recent_activities
      @statistics = load_dashboard_statistics
      @widgets = widgets_for_profile(current_user)
      render 'dashboard'
    else
      render 'landing'
    end
  end
  
  private
  
  def load_pending_documents
    # Documents nécessitant une action de l'utilisateur
    scope = Document.joins(:validation_requests)
                   .where(validation_requests: { assigned_to: current_user, status: 'pending' })
                   .includes(:uploaded_by, :space, file_attachment: :blob)
    
    # Ajouter les documents draft de l'utilisateur
    draft_docs = Document.where(status: 'draft', uploaded_by: current_user)
                        .includes(:uploaded_by, :space, file_attachment: :blob)
    
    # Ajouter les documents verrouillés par l'utilisateur
    locked_docs = Document.where(status: 'locked', locked_by: current_user)
                         .includes(:uploaded_by, :space, file_attachment: :blob)
    
    # Combiner et limiter
    (scope.or(draft_docs).or(locked_docs)).distinct.limit(10)
  end
  
  def load_recent_activities
    # Activités récentes liées aux documents de l'utilisateur
    activities = []
    
    # Documents récemment consultés
    if Document.reflect_on_association(:views)
      recent_views = Document.joins(:views)
                            .where(document_views: { user: current_user })
                            .where('document_views.created_at > ?', 7.days.ago)
                            .order('document_views.created_at DESC')
                            .limit(5)
      activities += recent_views
    end
    
    # Documents récemment uploadés
    recent_uploads = Document.where(uploaded_by: current_user)
                            .where('created_at > ?', 7.days.ago)
                            .order(created_at: :desc)
                            .limit(5)
    activities += recent_uploads
    
    # Documents récemment partagés
    if Document.reflect_on_association(:shares)
      recent_shares = Document.joins(:shares)
                             .where(shares: { shared_by: current_user })
                             .where('shares.created_at > ?', 7.days.ago)
                             .order('shares.created_at DESC')
                             .limit(5)
      activities += recent_shares
    end
    
    # Combiner et trier par date
    activities.uniq.sort_by(&:updated_at).reverse.first(10)
  end
  
  def load_dashboard_statistics
    {
      total_documents: current_user.accessible_documents.count,
      pending_validations: current_user.validation_requests.pending.count,
      shared_documents: current_user.shared_documents.count,
      storage_used: calculate_storage_used(current_user)
    }
  end
  
  def calculate_storage_used(user)
    total_bytes = user.documents.joins(file_attachment: :blob)
                     .sum('active_storage_blobs.byte_size')
    
    # Convertir en format lisible
    case total_bytes
    when 0..1.kilobyte
      "#{total_bytes} B"
    when 1.kilobyte..1.megabyte
      "#{(total_bytes.to_f / 1.kilobyte).round(1)} KB"
    when 1.megabyte..1.gigabyte
      "#{(total_bytes.to_f / 1.megabyte).round(1)} MB"
    else
      "#{(total_bytes.to_f / 1.gigabyte).round(2)} GB"
    end
  end
  
  def widgets_for_profile(user)
    # Widgets de base pour tous les utilisateurs
    widgets = [:pending_documents, :recent_activity, :quick_actions, :statistics]
    
    # Widgets spécialisés selon le profil
    profile_specific_widgets = case user.active_profile&.profile_type
    when 'direction'
      [:validation_queue, :compliance_alerts]
    when 'chef_projet' 
      [:project_documents]
    when 'commercial'
      [:client_documents]
    when 'juridique'
      [:compliance_alerts]
    else
      []
    end
    
    # Combiner les widgets et assurer l'unicité
    (widgets + profile_specific_widgets).uniq
  end
end
