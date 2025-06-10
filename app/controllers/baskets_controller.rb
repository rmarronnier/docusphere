class BasketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_basket, only: [:show, :edit, :update, :destroy, :share, :add_document, :remove_document, :download_all]
  
  def index
    skip_authorization
    @baskets = current_user.baskets.includes(:basket_items)
    @shared_baskets = Basket.shared.where.not(user: current_user)
  end
  
  def show
    skip_authorization
    @basket_items = @basket.basket_items.includes(item: [:space, :uploaded_by])
                                       .order(:position)
  end
  
  def new
    skip_authorization
    @basket = current_user.baskets.build
  end
  
  def create
    skip_authorization
    @basket = current_user.baskets.build(basket_params)
    
    if @basket.save
      redirect_to basket_path(@basket), notice: 'Bannette créée avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    skip_authorization
  end
  
  def update
    skip_authorization
    if @basket.update(basket_params)
      redirect_to basket_path(@basket), notice: 'Bannette mise à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    skip_authorization
    @basket.destroy
    redirect_to baskets_path, notice: 'Bannette supprimée avec succès.'
  end
  
  def share
    skip_authorization
    @basket.generate_share_token!
    redirect_to basket_path(@basket), notice: 'Lien de partage généré avec succès.'
  end
  
  def add_document
    skip_authorization
    document = Document.find(params[:document_id])
    
    # Verify user has access to the document
    unless document.readable_by?(current_user)
      redirect_back(fallback_location: baskets_path, alert: 'Vous n\'avez pas accès à ce document.')
      return
    end
    
    @basket.add_document(document)
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: baskets_path, notice: 'Document ajouté à la bannette.') }
      format.json { render json: { success: true, message: 'Document ajouté à la bannette.' } }
    end
  end
  
  def remove_document
    skip_authorization
    document = Document.find(params[:document_id])
    @basket.remove_document(document)
    
    respond_to do |format|
      format.html { redirect_to basket_path(@basket), notice: 'Document retiré de la bannette.' }
      format.json { render json: { success: true, message: 'Document retiré de la bannette.' } }
    end
  end
  
  def download_all
    skip_authorization
    
    # In a real implementation, this would create a ZIP file with all documents
    # For now, we'll just redirect with a message
    redirect_to basket_path(@basket), notice: 'Fonctionnalité de téléchargement groupé à venir.'
  end
  
  private
  
  def set_basket
    @basket = current_user.baskets.find(params[:id])
  end
  
  def basket_params
    params.require(:basket).permit(:name, :description)
  end
end