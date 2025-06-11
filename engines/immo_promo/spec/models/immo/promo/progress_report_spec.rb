require 'rails_helper'

RSpec.describe Immo::Promo::ProgressReport, type: :model do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:progress_report) { create(:immo_promo_progress_report, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Immo::Promo::Project') }
    it { is_expected.to belong_to(:prepared_by).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:report_date) }
    it { is_expected.to validate_numericality_of(:overall_progress).is_in(0..100) }
  end

  describe 'scopes' do
    let!(:recent_report) { create(:immo_promo_progress_report, project: project, report_date: 1.day.ago) }
    let!(:old_report) { create(:immo_promo_progress_report, project: project, report_date: 1.month.ago) }

    describe '.recent' do
      it 'returns recent reports' do
        reports = Immo::Promo::ProgressReport.recent
        expect(reports.first).to eq(recent_report)
      end
    end
  end
end