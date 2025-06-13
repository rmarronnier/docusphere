class GedController < ApplicationController
  include Ged::PermissionsManagement
  include Ged::DocumentLocking
  include Ged::DocumentVersioning
  include Ged::DocumentOperations
  include Ged::BreadcrumbBuilder
  include Ged::BulkOperations

  before_action :authenticate_user!
  before_action :set_space, only: [:show_space]
  before_action :set_space_for_folder, only: [:create_folder]
  before_action :set_folder, only: [:show_folder]
  before_action :set_document, only: [:show_document, :edit_document, :update_document, :lock_document, :unlock_document, :preview_document, :download_document]
  skip_after_action :verify_authorized, only: [:dashboard]

  def dashboard
    @favorite_spaces = policy_scope(Space).limit(6)
    @recent_documents = policy_scope(Document).includes(:space, :folder, :uploaded_by)
                                             .order(updated_at: :desc)
                                             .limit(10)
    @spaces_count = policy_scope(Space).count
    @documents_count = policy_scope(Document).count
  end

  def show_space
    # authorize already called in set_space
    @folders = @space.folders.roots.includes(:children)
    @documents = @space.documents.where(folder: nil).includes(:uploaded_by)
    @breadcrumbs = [{ name: 'GED', path: ged_dashboard_path }, { name: @space.name, path: ged_space_path(@space) }]
  end

  def show_folder
    # authorize already called in set_folder
    @space = @folder.space
    @subfolders = @folder.children.includes(:children)
    @documents = @folder.documents.includes(:uploaded_by)
    @breadcrumbs = build_folder_breadcrumbs(@folder)
  end

  def show_document
    # authorize already called in set_document
    @space = @document.space
    @folder = @document.folder
    @breadcrumbs = build_document_breadcrumbs(@document)
  end

  def create_space
    @space = current_user.organization.spaces.build(space_params)
    authorize @space, :create?
    
    if @space.save
      render json: { success: true, message: 'Espace créé avec succès', redirect_url: ged_space_path(@space) }
    else
      render json: { success: false, errors: @space.errors.full_messages }
    end
  end

  def create_folder
    @folder = @space.folders.build(folder_params)
    @folder.parent_id = params[:parent_id] if params[:parent_id].present?
    authorize @folder, :create?
    
    if @folder.save
      render json: { success: true, message: 'Dossier créé avec succès', redirect_url: ged_folder_path(@folder) }
    else
      render json: { success: false, errors: @folder.errors.full_messages }
    end
  end

  # Search functionality
  def search
    @query = params[:q]
    return redirect_to ged_dashboard_path if @query.blank?
    
    @documents = policy_scope(Document)
                  .includes(:space, :folder, :uploaded_by, :tags)
                  .search(@query)
                  .page(params[:page])
    
    @spaces = policy_scope(Space).where("name ILIKE ?", "%#{@query}%")
    @folders = policy_scope(Folder).where("name ILIKE ?", "%#{@query}%")
    
    @total_results = @documents.total_count + @spaces.count + @folders.count
  end

  # My documents
  def my_documents
    authorize :ged, :my_documents?
    
    # Base query for documents
    base_query = policy_scope(Document).where(uploaded_by: current_user)
    
    # Statistics (on unpaginated query)
    @total_count = base_query.count
    @week_count = base_query.where('created_at >= ?', 1.week.ago).count
    @spaces_count = base_query.distinct.count(:space_id)
    @tags_count = base_query.joins(:tags).count('DISTINCT tags.id')
    
    # Paginated documents for display
    @documents = base_query.includes(:space, :folder, :tags, :uploaded_by)
                          .order(updated_at: :desc)
                          .page(params[:page])
    
    @breadcrumbs = [
      { name: 'GED', path: ged_dashboard_path }, 
      { name: 'Mes documents', path: ged_my_documents_path }
    ]
    
    respond_to do |format|
      format.html { render :my_documents }
      format.json { render json: serialize_documents(@documents) }
    end
  end

  # Advanced search
  def advanced_search
    @documents = policy_scope(Document).includes(:space, :folder, :uploaded_by, :tags)
    
    # Apply filters
    @documents = @documents.where(document_type: params[:document_type]) if params[:document_type].present?
    @documents = @documents.where(status: params[:status]) if params[:status].present?
    @documents = @documents.where(space_id: params[:space_id]) if params[:space_id].present?
    @documents = @documents.where("created_at >= ?", params[:date_from]) if params[:date_from].present?
    @documents = @documents.where("created_at <= ?", params[:date_to]) if params[:date_to].present?
    @documents = @documents.joins(:tags).where(tags: { id: params[:tag_ids] }) if params[:tag_ids].present?
    
    # Search in content if query present
    @documents = @documents.search(params[:q]) if params[:q].present?
    
    @documents = @documents.page(params[:page])
    
    respond_to do |format|
      format.html
      format.json { render json: serialize_documents(@documents) }
    end
  end

  # New document (upload page)
  def new_document
    @document = Document.new
    authorize @document, :create?
    @spaces = policy_scope(Space).order(:name)
    @breadcrumbs = [
      { name: 'GED', path: ged_dashboard_path },
      { name: 'Upload', path: ged_upload_path }
    ]
  end
  
  # Upload document
  def upload_document
    @document = Document.new(document_params)
    @document.uploaded_by = current_user
    
    authorize @document, :create?
    
    if @document.save
      redirect_to ged_document_path(@document), notice: 'Document uploadé avec succès.'
    else
      @spaces = policy_scope(Space).order(:name)
      @breadcrumbs = [
        { name: 'GED', path: ged_dashboard_path },
        { name: 'Upload', path: ged_upload_path }
      ]
      render :new_document
    end
  end
  
  # Preview document
  def preview_document
    # authorize already called in set_document
    
    if @document.file.attached?
      if ENV['DOCUMENT_PROCESSOR_URL'].present?
        # Use document processor service to generate preview
        preview_url = "#{ENV['DOCUMENT_PROCESSOR_URL']}/preview/#{@document.id}"
        redirect_to preview_url
      else
        # Fallback to direct file display
        redirect_to rails_blob_path(@document.file, disposition: "inline")
      end
    else
      redirect_to ged_document_path(@document), alert: "Aucun fichier à prévisualiser"
    end
  end
  
  # Edit document
  def edit_document
    # authorize already called in set_document
    authorize @document, :update?
    @spaces = policy_scope(Space).order(:name)
    @breadcrumbs = build_document_breadcrumbs(@document)
  end
  
  # Update document
  def update_document
    # authorize already called in set_document
    authorize @document, :update?
    
    if @document.update(document_params)
      redirect_to ged_document_path(@document), notice: 'Document mis à jour avec succès.'
    else
      @spaces = policy_scope(Space).order(:name)
      @breadcrumbs = build_document_breadcrumbs(@document)
      render :edit_document
    end
  end
  
  # Download document
  def download_document
    # authorize already called in set_document
    
    if @document.file.attached?
      redirect_to rails_blob_path(@document.file, disposition: "attachment")
    else
      redirect_to ged_document_path(@document), alert: "Aucun fichier à télécharger"
    end
  end
  
  # Document statistics
  def document_statistics
    authorize :ged, :statistics?
    
    @stats = {
      total_documents: policy_scope(Document).count,
      documents_by_type: policy_scope(Document).group(:document_type).count,
      documents_by_status: policy_scope(Document).group(:status).count,
      documents_by_space: policy_scope(Document).joins(:space).group('spaces.name').count,
      recent_uploads: policy_scope(Document).where('created_at > ?', 30.days.ago).count,
      total_file_size: policy_scope(Document).sum(:file_size) || 0,
      ai_processed: policy_scope(Document).where.not(ai_processed_at: nil).count,
      compliance_issues: policy_scope(Document).joins(:tags).where(tags: { name: 'compliance:non-compliant' }).distinct.count
    }
    
    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  private

  def set_space
    @space = policy_scope(Space).find(params[:id])
    authorize @space, :show?
  end
  
  def set_space_for_folder
    @space = policy_scope(Space).find(params[:space_id])
    authorize @space, :show?
  end

  def set_folder
    @folder = policy_scope(Folder).find(params[:id])
    authorize @folder, :show?
  end

  def set_document
    @document = policy_scope(Document).find(params[:id])
    authorize @document, :show?
  end

  def space_params
    params.require(:space).permit(:name, :description)
  end

  def folder_params
    params.require(:folder).permit(:name, :description, :parent_id)
  end

  def document_params
    params.require(:document).permit(:title, :description, :file, :document_type, :tag_list, :document_category, :space_id, :folder_id)
  end

  def serialize_documents(documents)
    documents.map do |doc|
      {
        id: doc.id,
        title: doc.title,
        description: doc.description,
        document_type: doc.document_type,
        status: doc.status,
        file_size: doc.file_size,
        created_at: doc.created_at,
        updated_at: doc.updated_at,
        uploaded_by: doc.uploaded_by.full_name,
        space: doc.space.name,
        folder: doc.folder&.name,
        tags: doc.tags.pluck(:name),
        url: ged_document_path(doc)
      }
    end
  end
end