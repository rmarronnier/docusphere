class ContractsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_contracts_access!
  before_action :set_contract, only: [:show, :edit, :update, :destroy, :sign, :renew, :terminate]
  
  def index
    @contracts = policy_scope(Contract)
    @filter = params[:filter] || 'active'
    
    @contracts = case @filter
                 when 'active' then @contracts.active
                 when 'pending' then @contracts.pending
                 when 'expired' then @contracts.expired
                 when 'terminated' then @contracts.terminated
                 else @contracts
                 end
    
    @contracts = @contracts.includes(:client, :documents, :signatories).order(updated_at: :desc)
    @stats = calculate_contract_stats
    @upcoming_renewals = Contract.upcoming_renewals
  end
  
  def show
    @documents = @contract.documents.includes(:tags)
    @signatories = @contract.signatories
    @versions = @contract.versions.includes(:created_by)
    @financial_summary = calculate_financial_summary(@contract)
  end
  
  def new
    @contract = authorize Contract.new
    @contract.client_id = params[:client_id] if params[:client_id]
    @templates = ContractTemplate.active
  end
  
  def create
    @contract = authorize Contract.new(contract_params)
    @contract.created_by = current_user
    @contract.status = 'draft'
    
    if @contract.save
      attach_initial_document if params[:document]
      ContractNotificationJob.perform_later(@contract, 'created')
      redirect_to @contract, notice: 'Contrat créé avec succès'
    else
      @templates = ContractTemplate.active
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @templates = ContractTemplate.active
  end
  
  def update
    if @contract.update(contract_params)
      @contract.create_version!(current_user)
      redirect_to @contract, notice: 'Contrat mis à jour avec succès'
    else
      @templates = ContractTemplate.active
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @contract.can_be_deleted?
      @contract.destroy
      redirect_to contracts_path, notice: 'Contrat supprimé'
    else
      redirect_to @contract, alert: 'Ce contrat ne peut pas être supprimé'
    end
  end
  
  def sign
    @signatory = @contract.signatories.find_by(email: params[:email])
    
    if @signatory && @signatory.can_sign?
      @signatory.sign!(params[:signature_data])
      
      if @contract.all_signed?
        @contract.activate!
        ContractNotificationJob.perform_later(@contract, 'fully_signed')
      end
      
      redirect_to @contract, notice: 'Signature enregistrée avec succès'
    else
      redirect_to @contract, alert: 'Signature non autorisée'
    end
  end
  
  def renew
    @new_contract = @contract.duplicate_for_renewal
    @new_contract.start_date = @contract.end_date + 1.day
    @new_contract.end_date = @new_contract.start_date + @contract.duration_in_months.months
    
    if @new_contract.save
      @contract.mark_as_renewed!(@new_contract)
      redirect_to @new_contract, notice: 'Contrat renouvelé avec succès'
    else
      redirect_to @contract, alert: 'Erreur lors du renouvellement'
    end
  end
  
  def terminate
    if @contract.can_be_terminated?
      @contract.terminate!(reason: params[:reason], termination_date: params[:termination_date])
      ContractNotificationJob.perform_later(@contract, 'terminated')
      redirect_to @contract, notice: 'Contrat résilié'
    else
      redirect_to @contract, alert: 'Ce contrat ne peut pas être résilié'
    end
  end
  
  def templates
    @templates = authorize ContractTemplate.all
  end
  
  def generate_from_template
    @template = ContractTemplate.find(params[:template_id])
    @contract = @template.generate_contract(contract_params)
    
    if @contract.save
      redirect_to edit_contract_path(@contract), notice: 'Contrat généré à partir du modèle'
    else
      redirect_to new_contract_path, alert: 'Erreur lors de la génération'
    end
  end
  
  private
  
  def authorize_contracts_access!
    allowed_roles = [:commercial, :juridique, :direction, :admin]
    unless allowed_roles.any? { |role| current_user.has_role?(role) }
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def set_contract
    @contract = authorize Contract.find(params[:id])
  end
  
  def contract_params
    params.require(:contract).permit(:title, :client_id, :contract_type, :start_date,
                                    :end_date, :amount, :currency, :payment_terms,
                                    :auto_renewal, :notice_period, :terms_and_conditions,
                                    :special_clauses, signatory_emails: [])
  end
  
  def calculate_contract_stats
    {
      total: @contracts.count,
      active: @contracts.active.count,
      total_value: @contracts.active.sum(:amount),
      expiring_soon: @contracts.expiring_within(30.days).count,
      pending_signature: @contracts.pending_signature.count
    }
  end
  
  def calculate_financial_summary(contract)
    {
      total_value: contract.amount,
      paid_amount: contract.paid_amount,
      remaining_amount: contract.remaining_amount,
      next_payment_date: contract.next_payment_date,
      payment_schedule: contract.payment_schedule
    }
  end
  
  def attach_initial_document
    document = Document.new(
      name: "Contrat - #{@contract.title}",
      file: params[:document],
      documentable: @contract,
      uploaded_by: current_user,
      organization: current_user.organization
    )
    
    if document.save
      @contract.documents << document
    end
  end
end