class GedController < ApplicationController
  before_action :authenticate_user!
  before_action :set_space, only: [:show_space, :create_folder]
  before_action :set_folder, only: [:show_folder]
  before_action :set_document, only: [:show_document]

  def dashboard
    skip_authorization
    @favorite_spaces = current_user.organization.spaces.limit(6)
    @recent_documents = Document.where(user: current_user)
                               .includes(:space, :folder)
                               .order(updated_at: :desc)
                               .limit(10)
    @spaces_count = current_user.organization.spaces.count
    @documents_count = Document.joins(:space).where(spaces: { organization: current_user.organization }).count
  end

  def show_space
    skip_authorization
    @folders = @space.folders.roots.includes(:children)
    @documents = @space.documents.where(folder: nil).includes(:user)
    @breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }, { name: @space.name, path: ged_space_path(@space) }]
  end

  def show_folder
    skip_authorization
    @space = @folder.space
    @subfolders = @folder.children.includes(:children)
    @documents = @folder.documents.includes(:user)
    @breadcrumbs = build_folder_breadcrumbs(@folder)
  end

  def show_document
    skip_authorization
    @space = @document.space
    @folder = @document.folder
    @breadcrumbs = build_document_breadcrumbs(@document)
  end

  def create_space
    skip_authorization
    @space = current_user.organization.spaces.build(space_params)
    
    if @space.save
      render json: { success: true, message: 'Espace créé avec succès', redirect_url: ged_space_path(@space) }
    else
      render json: { success: false, errors: @space.errors.full_messages }
    end
  end

  def create_folder
    skip_authorization
    @folder = @space.folders.build(folder_params)
    @folder.parent_id = params[:parent_id] if params[:parent_id].present?
    
    if @folder.save
      redirect_path = @folder.parent ? ged_folder_path(@folder.parent) : ged_space_path(@space)
      render json: { success: true, message: 'Dossier créé avec succès', redirect_url: redirect_path }
    else
      render json: { success: false, errors: @folder.errors.full_messages }
    end
  end

  def upload_document
    skip_authorization
    @document = Document.new(document_params)
    @document.user = current_user
    
    if @document.save
      redirect_path = @document.folder ? ged_folder_path(@document.folder) : ged_space_path(@document.space)
      render json: { 
        success: true, 
        message: 'Document uploadé avec succès. Le traitement est en cours...',
        redirect_url: redirect_path,
        document: {
          id: @document.id,
          title: @document.title,
          processing_status: @document.processing_status,
          file_size: @document.file_size,
          content_type: @document.file.content_type
        }
      }
    else
      render json: { success: false, errors: @document.errors.full_messages }
    end
  end
  
  def document_status
    skip_authorization
    @document = Document.find(params[:id])
    
    render json: {
      id: @document.id,
      processing_status: @document.processing_status,
      virus_scan_status: @document.virus_scan_status,
      preview_generated: @document.preview_generated?,
      thumbnail_generated: @document.thumbnail_generated?,
      ocr_performed: @document.ocr_performed,
      extracted_content: @document.content.present?,
      tags_count: @document.tags.count,
      metadata_count: @document.metadata.count,
      processing_error: @document.processing_error
    }
  end

  private

  def set_space
    @space = current_user.organization.spaces.find(params[:space_id] || params[:id])
  end

  def set_folder
    @folder = Folder.find(params[:id])
    # Vérifier que le dossier appartient à l'organisation de l'utilisateur
    unless @folder.space.organization == current_user.organization
      redirect_to ged_dashboard_path, alert: 'Accès non autorisé'
    end
  end

  def set_document
    @document = Document.find(params[:id])
    # Vérifier que le document appartient à l'organisation de l'utilisateur
    unless @document.space.organization == current_user.organization
      redirect_to ged_dashboard_path, alert: 'Accès non autorisé'
    end
  end

  def space_params
    params.require(:space).permit(:name, :description)
  end

  def folder_params
    params.require(:folder).permit(:name, :description)
  end

  def document_params
    params.require(:document).permit(:title, :description, :file, :space_id, :folder_id)
  end

  def build_folder_breadcrumbs(folder)
    breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }]
    breadcrumbs << { name: folder.space.name, path: ged_space_path(folder.space) }
    
    folder.ancestors.each do |ancestor|
      breadcrumbs << { name: ancestor.name, path: ged_folder_path(ancestor) }
    end
    
    breadcrumbs << { name: folder.name, path: ged_folder_path(folder) }
    breadcrumbs
  end

  def build_document_breadcrumbs(document)
    breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }]
    breadcrumbs << { name: document.space.name, path: ged_space_path(document.space) }
    
    if document.folder
      document.folder.ancestors.each do |ancestor|
        breadcrumbs << { name: ancestor.name, path: ged_folder_path(ancestor) }
      end
      breadcrumbs << { name: document.folder.name, path: ged_folder_path(document.folder) }
    end
    
    breadcrumbs << { name: document.title, path: ged_document_path(document) }
    breadcrumbs
  end
end