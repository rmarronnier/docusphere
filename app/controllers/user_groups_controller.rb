class UserGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!
  before_action :set_user_group, only: [:show, :edit, :update, :destroy, :add_member, :remove_member]

  def index
    @user_groups = policy_scope(UserGroup)
      .includes(:users)
      .order(:name)
    
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @user_groups = @user_groups.where("name ILIKE ? OR description ILIKE ?", search_term, search_term)
    end
    
    @user_groups = @user_groups.page(params[:page]).per(20)
  end

  def show
    authorize @user_group
    @members = @user_group.user_group_memberships.includes(:user).order('users.last_name, users.first_name')
  end

  def new
    @user_group = UserGroup.new(organization: current_user.organization)
    authorize @user_group
  end

  def create
    @user_group = UserGroup.new(user_group_params)
    @user_group.organization = current_user.organization
    authorize @user_group
    
    if @user_group.save
      redirect_to user_group_path(@user_group), notice: 'Groupe créé avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user_group
  end

  def update
    authorize @user_group
    
    if @user_group.update(user_group_params)
      redirect_to user_group_path(@user_group), notice: 'Groupe mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user_group
    @user_group.destroy
    redirect_to user_groups_path, notice: 'Groupe supprimé avec succès.'
  end

  def add_member
    authorize @user_group
    user = User.find(params[:user_id])
    
    if user.organization != @user_group.organization
      redirect_to user_group_path(@user_group), alert: 'Cet utilisateur n\'appartient pas à la même organisation.'
      return
    end
    
    membership = @user_group.add_user(user, role: params[:role] || 'member')
    
    if membership.persisted?
      redirect_to user_group_path(@user_group), notice: 'Membre ajouté avec succès.'
    else
      redirect_to user_group_path(@user_group), alert: 'Erreur lors de l\'ajout du membre.'
    end
  end

  def remove_member
    authorize @user_group
    user = User.find(params[:user_id])
    
    @user_group.remove_user(user)
    redirect_to user_group_path(@user_group), notice: 'Membre retiré avec succès.'
  end

  private

  def set_user_group
    @user_group = UserGroup.find(params[:id])
  end

  def user_group_params
    params.require(:user_group).permit(:name, :description, :group_type, :is_active, permissions: {})
  end

  def authorize_admin!
    unless current_user.admin? || current_user.super_admin?
      redirect_to root_path, alert: 'Accès refusé.'
    end
  end
end