class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_finance_access!
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :send_invoice, :mark_as_paid, :generate_reminder]
  
  def index
    @invoices = policy_scope(Invoice)
    @filter = params[:filter] || 'all'
    
    @invoices = case @filter
                when 'pending' then @invoices.pending
                when 'paid' then @invoices.paid
                when 'overdue' then @invoices.overdue
                when 'cancelled' then @invoices.cancelled
                when 'draft' then @invoices.draft
                else @invoices
                end
    
    @invoices = @invoices.includes(:client, :invoice_items, :payments)
                         .order(created_at: :desc)
    
    @statistics = calculate_invoice_statistics
    @cash_flow_summary = build_cash_flow_summary
  end
  
  def show
    @invoice_items = @invoice.invoice_items.includes(:product_or_service)
    @payments = @invoice.payments.includes(:payment_method)
    @timeline = @invoice.activity_timeline
    @related_documents = @invoice.documents
  end
  
  def new
    @invoice = authorize Invoice.new
    @invoice.client_id = params[:client_id] if params[:client_id]
    @invoice.invoice_date = Date.current
    @invoice.due_date = Date.current + 30.days
    @products_services = ProductService.active
    @tax_rates = TaxRate.active
  end
  
  def create
    @invoice = authorize Invoice.new(invoice_params)
    @invoice.created_by = current_user
    @invoice.invoice_number = generate_invoice_number
    
    if @invoice.save
      InvoiceCalculationService.new(@invoice).calculate_totals
      InvoiceNotificationJob.perform_later(@invoice, 'created')
      redirect_to @invoice, notice: 'Facture créée avec succès'
    else
      @products_services = ProductService.active
      @tax_rates = TaxRate.active
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @products_services = ProductService.active
    @tax_rates = TaxRate.active
  end
  
  def update
    if @invoice.update(invoice_params)
      InvoiceCalculationService.new(@invoice).calculate_totals
      @invoice.create_version!(current_user)
      redirect_to @invoice, notice: 'Facture mise à jour avec succès'
    else
      @products_services = ProductService.active
      @tax_rates = TaxRate.active
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @invoice.can_be_deleted?
      @invoice.cancel!(reason: params[:reason], cancelled_by: current_user)
      redirect_to invoices_path, notice: 'Facture annulée'
    else
      redirect_to @invoice, alert: 'Cette facture ne peut pas être supprimée'
    end
  end
  
  def send_invoice
    if @invoice.can_be_sent?
      InvoiceSenderService.new(@invoice).send_to_client(
        email_message: params[:email_message],
        cc_emails: params[:cc_emails]
      )
      @invoice.mark_as_sent!
      redirect_to @invoice, notice: 'Facture envoyée au client'
    else
      redirect_to @invoice, alert: 'Cette facture ne peut pas être envoyée'
    end
  end
  
  def mark_as_paid
    if @invoice.pending?
      @payment = @invoice.payments.build(
        amount: params[:amount] || @invoice.total_amount,
        payment_date: params[:payment_date] || Date.current,
        payment_method_id: params[:payment_method_id],
        reference: params[:reference]
      )
      
      if @payment.save
        @invoice.update_payment_status!
        redirect_to @invoice, notice: 'Paiement enregistré avec succès'
      else
        redirect_to @invoice, alert: 'Erreur lors de l\'enregistrement du paiement'
      end
    else
      redirect_to @invoice, alert: 'Cette facture n\'est pas en attente de paiement'
    end
  end
  
  def generate_reminder
    if @invoice.overdue?
      reminder = InvoiceReminderService.new(@invoice).generate_reminder(
        reminder_level: @invoice.reminder_count + 1
      )
      
      if reminder.persisted?
        InvoiceReminderJob.perform_later(reminder)
        redirect_to @invoice, notice: 'Relance générée et envoyée'
      else
        redirect_to @invoice, alert: 'Erreur lors de la génération de la relance'
      end
    else
      redirect_to @invoice, alert: 'Cette facture n\'est pas en retard'
    end
  end
  
  def bulk_actions
    invoice_ids = params[:invoice_ids]
    action = params[:bulk_action]
    
    case action
    when 'send_reminders'
      BulkInvoiceReminderJob.perform_later(invoice_ids)
      redirect_to invoices_path, notice: 'Relances en cours d\'envoi'
    when 'export'
      export_invoices(Invoice.where(id: invoice_ids))
    when 'generate_report'
      redirect_to invoice_report_path(invoice_ids: invoice_ids)
    else
      redirect_to invoices_path, alert: 'Action non reconnue'
    end
  end
  
  def reconciliation
    @period = params[:period] || Date.current.strftime('%Y-%m')
    @invoices = Invoice.for_period(@period)
    @payments = Payment.for_period(@period)
    @discrepancies = ReconciliationService.new(@period).find_discrepancies
  end
  
  def aging_report
    @as_of_date = params[:as_of_date] || Date.current
    @aging_buckets = InvoiceAgingService.new(@as_of_date).calculate_aging
    @summary = build_aging_summary(@aging_buckets)
    
    respond_to do |format|
      format.html
      format.pdf { send_data generate_aging_pdf, filename: "aging_report_#{@as_of_date}.pdf" }
      format.xlsx { send_data generate_aging_excel, filename: "aging_report_#{@as_of_date}.xlsx" }
    end
  end
  
  private
  
  def authorize_finance_access!
    unless current_user.has_role?(:finance) || current_user.has_role?(:direction) || current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def set_invoice
    @invoice = authorize Invoice.find(params[:id])
  end
  
  def invoice_params
    params.require(:invoice).permit(:client_id, :invoice_date, :due_date, 
                                    :payment_terms, :currency, :notes,
                                    :billing_address, :shipping_address,
                                    invoice_items_attributes: [:id, :description, :quantity,
                                                              :unit_price, :tax_rate_id,
                                                              :discount_percentage, :_destroy])
  end
  
  def calculate_invoice_statistics
    {
      total_count: @invoices.count,
      total_amount: @invoices.sum(:total_amount),
      paid_amount: @invoices.paid.sum(:total_amount),
      pending_amount: @invoices.pending.sum(:total_amount),
      overdue_amount: @invoices.overdue.sum(:total_amount),
      average_payment_time: Invoice.average_payment_time,
      collection_rate: Invoice.collection_rate
    }
  end
  
  def build_cash_flow_summary
    {
      expected_income: Invoice.pending.sum(:total_amount),
      overdue_receivables: Invoice.overdue.sum(:total_amount),
      this_month_invoiced: Invoice.this_month.sum(:total_amount),
      this_month_collected: Payment.this_month.sum(:amount)
    }
  end
  
  def generate_invoice_number
    prefix = "INV"
    year = Date.current.year
    sequence = Invoice.where("invoice_number LIKE ?", "#{prefix}-#{year}-%").count + 1
    "#{prefix}-#{year}-#{sequence.to_s.rjust(5, '0')}"
  end
  
  def export_invoices(invoices)
    respond_to do |format|
      format.csv { send_data InvoiceExportService.new(invoices).to_csv, filename: "invoices_#{Date.current}.csv" }
      format.xlsx { send_data InvoiceExportService.new(invoices).to_excel, filename: "invoices_#{Date.current}.xlsx" }
      format.pdf { send_data InvoiceExportService.new(invoices).to_pdf, filename: "invoices_#{Date.current}.pdf" }
    end
  end
  
  def build_aging_summary(buckets)
    {
      current: buckets[:current].sum(&:total_amount),
      overdue_30: buckets[:days_30].sum(&:total_amount),
      overdue_60: buckets[:days_60].sum(&:total_amount),
      overdue_90: buckets[:days_90].sum(&:total_amount),
      overdue_plus: buckets[:days_plus].sum(&:total_amount)
    }
  end
  
  def generate_aging_pdf
    # PDF generation logic
    ""
  end
  
  def generate_aging_excel
    # Excel generation logic
    ""
  end
end