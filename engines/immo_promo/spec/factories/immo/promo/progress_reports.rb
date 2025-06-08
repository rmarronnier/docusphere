FactoryBot.define do
  factory :immo_promo_progress_report, class: 'Immo::Promo::ProgressReport' do
    association :project, factory: :immo_promo_project
    association :created_by, factory: :user
    report_date { Date.current }
    period_start { 1.month.ago }
    period_end { Date.current }
    overall_progress { 45 }
    status_summary { 'Projet en bonne voie' }
    key_achievements { 'Fondations terminées' }
    issues_risks { 'Retard potentiel sur les permis' }
    next_steps { 'Démarrage de la structure' }
  end
end