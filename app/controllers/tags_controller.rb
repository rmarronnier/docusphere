class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tag, only: [:show, :edit, :update, :destroy]

  def index
    @tags = policy_scope(Tag)
      .includes(:documents)
      .order(:name)
    
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @tags = @tags.where("name ILIKE ?", search_term)
    end
    
    @tags = @tags.page(params[:page]).per(30)
  end

  def show
    authorize @tag
    @documents = @tag.documents.includes(:uploaded_by, :space).page(params[:page]).per(20)
  end

  def new
    @tag = Tag.new(organization: current_user.organization)
    authorize @tag
  end

  def create
    @tag = Tag.new(tag_params)
    @tag.organization = current_user.organization
    authorize @tag
    
    if @tag.save
      redirect_to tag_path(@tag), notice: 'Tag créé avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @tag
  end

  def update
    authorize @tag
    
    if @tag.update(tag_params)
      redirect_to tag_path(@tag), notice: 'Tag mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @tag
    @tag.destroy
    redirect_to tags_path, notice: 'Tag supprimé avec succès.'
  end

  def autocomplete
    @tags = policy_scope(Tag)
      .where("name ILIKE ?", "%#{params[:q]}%")
      .order(:name)
      .limit(10)
    
    render json: @tags.map { |tag| { id: tag.id, name: tag.name, color: tag.color } }
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    permitted_attributes(@tag || Tag.new)
  end
end