class LegalDeadlinesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_juridique_access!
  before_action :set_deadline, only: [:show, :edit, :update, :destroy, :complete, :extend]
  
  def index
    @deadlines = policy_scope(LegalDeadline)
    @filter = params[:filter] || 'upcoming'
    
    @deadlines = case @filter
                 when 'upcoming' then @deadlines.upcoming
                 when 'overdue' then @deadlines.overdue
                 when 'this_week' then @deadlines.this_week
                 when 'this_month' then @deadlines.this_month
                 when 'completed' then @deadlines.completed
                 else @deadlines.active
                 end
    
    @deadlines = @deadlines.includes(:responsible_user, :related_contract, :documents)
                           .order(due_date: :asc)
    
    @calendar_deadlines = build_calendar_data(@deadlines)
    @statistics = calculate_deadline_statistics
  end
  
  def show
    @related_documents = @deadline.documents.includes(:tags)
    @activity_log = @deadline.activities.includes(:user).recent
    @compliance_status = @deadline.check_compliance_status
    @extensions = @deadline.extensions.includes(:requested_by)
  end
  
  def new
    @deadline = authorize LegalDeadline.new
    @deadline.due_date = params[:due_date] if params[:due_date]
    @contracts = Contract.active
    @deadline_types = LegalDeadlineType.active
  end
  
  def create
    @deadline = authorize LegalDeadline.new(deadline_params)
    @deadline.created_by = current_user
    
    if @deadline.save
      schedule_reminders
      NotificationService.new.notify_deadline_created(@deadline)
      redirect_to @deadline, notice: 'Échéance légale créée avec succès'
    else
      @contracts = Contract.active
      @deadline_types = LegalDeadlineType.active
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @contracts = Contract.active
    @deadline_types = LegalDeadlineType.active
  end
  
  def update
    if @deadline.update(deadline_params)
      reschedule_reminders if @deadline.saved_change_to_due_date?
      redirect_to @deadline, notice: 'Échéance mise à jour avec succès'
    else
      @contracts = Contract.active
      @deadline_types = LegalDeadlineType.active
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @deadline.cancel!(reason: params[:reason], cancelled_by: current_user)
    redirect_to legal_deadlines_path, notice: 'Échéance annulée'
  end
  
  def complete
    if @deadline.can_be_completed?
      @deadline.complete!(
        completed_by: current_user,
        completion_notes: params[:completion_notes],
        supporting_documents: params[:document_ids]
      )
      redirect_to @deadline, notice: 'Échéance marquée comme complétée'
    else
      redirect_to @deadline, alert: 'Cette échéance ne peut pas être complétée'
    end
  end
  
  def extend
    @extension = @deadline.extensions.build(
      requested_by: current_user,
      new_due_date: params[:new_due_date],
      reason: params[:reason],
      approved: false
    )
    
    if @extension.save
      DeadlineExtensionApprovalJob.perform_later(@extension)
      redirect_to @deadline, notice: 'Demande d\'extension envoyée'
    else
      redirect_to @deadline, alert: 'Erreur lors de la demande d\'extension'
    end
  end
  
  def calendar
    @view_type = params[:view] || 'month'
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @deadlines = LegalDeadline.in_date_range(date_range_for_view(@date, @view_type))
    
    respond_to do |format|
      format.html
      format.json { render json: calendar_json(@deadlines) }
      format.ics { send_data generate_ical(@deadlines), filename: 'legal_deadlines.ics' }
    end
  end
  
  def dashboard
    @critical_deadlines = LegalDeadline.critical.upcoming
    @overdue_count = LegalDeadline.overdue.count
    @this_week_count = LegalDeadline.this_week.count
    @compliance_rate = calculate_compliance_rate
    @deadline_by_type = LegalDeadline.group_by_type_with_counts
    @responsible_summary = build_responsible_summary
  end
  
  def export
    @deadlines = policy_scope(LegalDeadline).includes(:responsible_user, :related_contract)
    
    respond_to do |format|
      format.csv { send_data generate_csv(@deadlines), filename: "legal_deadlines_#{Date.current}.csv" }
      format.xlsx { send_data generate_excel(@deadlines), filename: "legal_deadlines_#{Date.current}.xlsx" }
      format.pdf { send_data generate_pdf_report(@deadlines), filename: "legal_deadlines_#{Date.current}.pdf" }
    end
  end
  
  private
  
  def authorize_juridique_access!
    unless current_user.has_role?(:juridique) || current_user.has_role?(:direction) || current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  end
  
  def set_deadline
    @deadline = authorize LegalDeadline.find(params[:id])
  end
  
  def deadline_params
    params.require(:legal_deadline).permit(:title, :description, :due_date, :deadline_type_id,
                                          :related_contract_id, :responsible_user_id,
                                          :priority, :recurring, :recurrence_pattern,
                                          :reminder_days_before, :legal_requirement,
                                          :regulatory_reference, :penalties_if_missed,
                                          :tags, document_ids: [])
  end
  
  def calculate_deadline_statistics
    {
      total: @deadlines.count,
      overdue: LegalDeadline.overdue.count,
      upcoming_7_days: LegalDeadline.upcoming_days(7).count,
      upcoming_30_days: LegalDeadline.upcoming_days(30).count,
      completion_rate: LegalDeadline.completion_rate,
      average_completion_time: LegalDeadline.average_completion_time
    }
  end
  
  def build_calendar_data(deadlines)
    deadlines.map do |deadline|
      {
        id: deadline.id,
        title: deadline.title,
        start: deadline.due_date,
        allDay: true,
        color: deadline_color(deadline),
        url: legal_deadline_path(deadline)
      }
    end
  end
  
  def deadline_color(deadline)
    if deadline.overdue?
      '#dc3545' # red
    elsif deadline.due_date <= 7.days.from_now
      '#ffc107' # yellow
    elsif deadline.high_priority?
      '#fd7e14' # orange
    else
      '#28a745' # green
    end
  end
  
  def schedule_reminders
    if @deadline.reminder_days_before.present?
      @deadline.reminder_days_before.each do |days|
        DeadlineReminderJob.set(wait_until: @deadline.due_date - days.days)
                           .perform_later(@deadline)
      end
    end
  end
  
  def reschedule_reminders
    # Cancel old reminders and schedule new ones
    @deadline.cancel_pending_reminders!
    schedule_reminders
  end
  
  def date_range_for_view(date, view_type)
    case view_type
    when 'day' then date.beginning_of_day..date.end_of_day
    when 'week' then date.beginning_of_week..date.end_of_week
    when 'month' then date.beginning_of_month..date.end_of_month
    else date.beginning_of_month..date.end_of_month
    end
  end
  
  def calendar_json(deadlines)
    {
      events: build_calendar_data(deadlines),
      statistics: {
        total: deadlines.count,
        overdue: deadlines.overdue.count,
        this_week: deadlines.this_week.count
      }
    }
  end
  
  def generate_ical(deadlines)
    cal = Icalendar::Calendar.new
    deadlines.each do |deadline|
      cal.event do |e|
        e.dtstart = Icalendar::Values::Date.new(deadline.due_date)
        e.summary = deadline.title
        e.description = deadline.description
        e.alarm do |a|
          a.action = "DISPLAY"
          a.summary = "Échéance: #{deadline.title}"
          a.trigger = "-P#{deadline.reminder_days_before.first || 1}D"
        end
      end
    end
    cal.to_ical
  end
  
  def calculate_compliance_rate
    total = LegalDeadline.count
    return 0 if total.zero?
    
    completed_on_time = LegalDeadline.completed.on_time.count
    (completed_on_time.to_f / total * 100).round(2)
  end
  
  def build_responsible_summary
    User.joins(:legal_deadlines)
        .group(:id, :name)
        .select('users.id, users.name, COUNT(legal_deadlines.id) as deadline_count')
        .map { |u| { name: u.name, count: u.deadline_count } }
  end
  
  def generate_csv(deadlines)
    CSV.generate(headers: true) do |csv|
      csv << ['Titre', 'Date limite', 'Type', 'Responsable', 'Statut', 'Priorité']
      deadlines.each do |deadline|
        csv << [
          deadline.title,
          deadline.due_date.strftime('%d/%m/%Y'),
          deadline.deadline_type&.name,
          deadline.responsible_user&.name,
          deadline.status,
          deadline.priority
        ]
      end
    end
  end
  
  def generate_excel(deadlines)
    # Excel generation logic
    ""
  end
  
  def generate_pdf_report(deadlines)
    # PDF report generation logic
    ""
  end
end