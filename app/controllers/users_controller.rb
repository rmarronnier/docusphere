class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = policy_scope(User)
      .includes(:organization, :user_groups)
      .order(:last_name, :first_name)
    
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
        search_term, search_term, search_term
      )
    end
    
    @users = @users.page(params[:page]).per(20)
  end

  def show
    authorize @user
  end

  def new
    @user = User.new(organization: current_user.organization)
    authorize @user
  end

  def create
    @user = User.new(user_params)
    @user.organization = current_user.organization
    authorize @user
    
    if @user.save
      redirect_to user_path(@user), notice: 'Utilisateur créé avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    
    # Remove password params if they're blank
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    
    if @user.update(user_params)
      redirect_to user_path(@user), notice: 'Utilisateur mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    
    if @user == current_user
      redirect_to users_path, alert: 'Vous ne pouvez pas supprimer votre propre compte.'
      return
    end
    
    @user.destroy
    redirect_to users_path, notice: 'Utilisateur supprimé avec succès.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted_attributes(@user || User.new)
  end

  def authorize_admin!
    unless current_user.admin? || current_user.super_admin?
      redirect_to root_path, alert: 'Accès refusé.'
    end
  end
end