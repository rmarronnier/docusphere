# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_direction_access

  def index
    @reports = []
    render 'coming_soon'
  end

  def show
    @report = nil
    render 'coming_soon'
  end

  def new
    @report = nil
    render 'coming_soon'
  end

  def create
    redirect_to reports_path, notice: "Cette fonctionnalité sera bientôt disponible"
  end

  def executive_summary
    render 'coming_soon'
  end

  def performance_dashboard
    render 'coming_soon'
  end

  def export
    redirect_to reports_path, notice: "Export sera bientôt disponible"
  end

  private

  def authorize_direction_access
    unless current_user.profile_type == 'direction' || current_user.admin?
      redirect_to root_path, alert: "Accès non autorisé"
    end
  end
end