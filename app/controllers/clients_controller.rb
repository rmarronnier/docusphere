class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_commercial_access!
  before_action :set_client, only: [:show, :edit, :update, :destroy, :documents, :history]
  
  def index
    @clients = policy_scope(Client)
    @filter = params[:filter] || 'all'
    
    @clients = case @filter
               when 'active' then @clients.active
               when 'prospect' then @clients.prospects
               when 'inactive' then @clients.inactive
               else @clients
               end
    
    @clients = @clients.includes(:documents, :proposals).order(updated_at: :desc)
    @stats = calculate_client_stats
  end
  
  def show
    @recent_documents = @client.documents.recent.limit(10)
    @proposals = @client.proposals.includes(:documents)
    @contracts = @client.contracts.active
    @activities = @client.activities.recent.limit(20)
  end
  
  def new
    @client = authorize Client.new
  end
  
  def create
    @client = authorize Client.new(client_params)
    @client.created_by = current_user
    
    if @client.save
      create_initial_folder(@client)
      redirect_to @client, notice: 'Client créé avec succès'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @client.update(client_params)
      redirect_to @client, notice: 'Client mis à jour avec succès'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @client.destroy
    redirect_to clients_path, notice: 'Client supprimé'
  end
  
  def documents
    @documents = @client.documents.includes(:tags, :uploaded_by)
    @shared_documents = @client.shared_documents
    
    respond_to do |format|
      format.html
      format.json { render json: @documents }
    end
  end
  
  def history
    @activities = @client.activities.includes(:user).order(created_at: :desc)
    @timeline_data = build_timeline_data(@activities)
  end
  
  def import
    if params[:file].present?
      result = ClientImportService.new(params[:file], current_user).import
      if result[:success]
        redirect_to clients_path, notice: "#{result[:imported]} clients importés avec succès"
      else
        redirect_to clients_path, alert: result[:error]
      end
    else
      redirect_to clients_path, alert: 'Veuillez sélectionner un fichier'
    end
  end
  
  def export
    @clients = policy_scope(Client)
    
    respond_to do |format|
      format.csv { send_data generate_csv(@clients), filename: "clients_#{Date.current}.csv" }
      format.xlsx { send_data generate_excel(@clients), filename: "clients_#{Date.current}.xlsx" }
    end
  end
  
  private
  
  def authorize_commercial_access!
    unless current_user.has_role?(:commercial) || current_user.has_role?(:direction) || current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def set_client
    @client = authorize Client.find(params[:id])
  end
  
  def client_params
    params.require(:client).permit(:name, :email, :phone, :address, :city, :postal_code,
                                   :country, :client_type, :status, :notes, :siret,
                                   :contact_name, :contact_email, :contact_phone)
  end
  
  def calculate_client_stats
    {
      total: @clients.count,
      active: @clients.active.count,
      prospects: @clients.prospects.count,
      new_this_month: @clients.where(created_at: Date.current.beginning_of_month..).count,
      revenue_this_month: calculate_monthly_revenue
    }
  end
  
  def create_initial_folder(client)
    folder = Folder.create!(
      name: client.name,
      parent: commercial_root_folder,
      created_by: current_user,
      organization: current_user.organization
    )
    
    client.update(folder_id: folder.id)
  end
  
  def commercial_root_folder
    Space.find_or_create_by(name: 'Commercial', organization: current_user.organization)
  end
  
  def build_timeline_data(activities)
    activities.group_by { |a| a.created_at.to_date }.map do |date, acts|
      {
        date: date,
        activities: acts.map { |a| activity_to_timeline_item(a) }
      }
    end
  end
  
  def activity_to_timeline_item(activity)
    {
      time: activity.created_at,
      type: activity.activity_type,
      description: activity.description,
      user: activity.user&.name
    }
  end
  
  def generate_csv(clients)
    CSV.generate(headers: true) do |csv|
      csv << ['Nom', 'Email', 'Téléphone', 'Type', 'Statut', 'Créé le']
      clients.each do |client|
        csv << [
          client.name,
          client.email,
          client.phone,
          client.client_type,
          client.status,
          client.created_at.strftime('%d/%m/%Y')
        ]
      end
    end
  end
  
  def generate_excel(clients)
    # Génération Excel avec axlsx ou similaire
    ""
  end
  
  def calculate_monthly_revenue
    # Calcul du CA mensuel basé sur les contrats
    0
  end
end