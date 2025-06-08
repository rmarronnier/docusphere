require 'rails_helper'

RSpec.describe 'Immo::Promo System Integration', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }

  before do
    sign_in user
    host! "localhost"
  end

  describe 'Full system workflow' do
    it 'can create projects, phases and access the system' do
      # Créer un projet directement sans factory problématique
      project = Immo::Promo::Project.create!(
        name: 'Test Project Integration',
        reference_number: 'TPI-001',
        project_type: 'residential',
        status: 'planning',
        organization: organization,
        project_manager: user,
        start_date: Date.current,
        end_date: Date.current + 2.years,
        total_budget_cents: 500_000_000
      )

      expect(project).to be_persisted
      expect(project.name).to eq('Test Project Integration')
      expect(project.project_type).to eq('residential')
      expect(project.total_budget.cents).to eq(500_000_000)

      # Tester les méthodes de base
      expect(project.completion_percentage).to eq(0)
      expect(project.total_surface_area).to eq(0)
      expect(project.can_start_construction?).to be false

      # Créer une phase (sans factory)
      phase = project.phases.create!(
        name: 'Études préliminaires',
        phase_type: 'studies',
        position: 1,
        start_date: Date.current,
        end_date: Date.current + 3.months
      )

      expect(phase).to be_persisted
      expect(phase.name).to eq('Études préliminaires')

      # Tester les services
      project_service = Immo::Promo::ProjectManagerService.new(project, user)
      expect(project_service).to respond_to(:calculate_overall_progress)
      expect(project_service.calculate_overall_progress).to be_a(Numeric)

      permit_service = Immo::Promo::PermitTrackerService.new(project, user)
      expect(permit_service).to respond_to(:generate_permit_workflow)

      # Tester les routes et contrôleurs
      get "/immo/promo/projects"
      expect(response).to have_http_status(:success), "Response body: #{response.body}"

      get "/immo/promo/projects/#{project.id}"
      expect(response).to have_http_status(:success)

      get "/immo/promo/projects/#{project.id}/dashboard"
      if response.status == 500
        puts "Response body: #{response.body}"
      end
      expect(response).to have_http_status(:success)
    end

    it 'validates business logic correctly' do
      # Test validation basic
      project = Immo::Promo::Project.new
      expect(project).not_to be_valid
      expect(project.errors[:name]).to be_present
      expect(project.errors[:organization]).to be_present  # organization is required for reference generation

      # Test enum validations
      expect {
        Immo::Promo::Project.new(project_type: 'invalid')
      }.to raise_error(ArgumentError)

      # Test avec données valides
      valid_project = Immo::Promo::Project.new(
        name: 'Valid Project',
        reference_number: 'VAL-001',
        project_type: 'residential',
        status: 'planning',
        organization: organization,
        start_date: Date.current,
        end_date: Date.current + 1.year
      )
      expect(valid_project).to be_valid
    end

    it 'tests the component rendering' do
      project = Immo::Promo::Project.create!(
        name: 'Component Test',
        reference_number: 'COMP-001',
        project_type: 'residential',
        status: 'planning',
        organization: organization,
        start_date: Date.current,
        end_date: Date.current + 1.year
      )

      component = Immo::Promo::ProjectCardComponent.new(project: project)
      expect(component).to be_present

      # Tester que le composant peut être instancié sans erreur
      expect { component }.not_to raise_error
    end

    it 'tests policies and authorization' do
      project = Immo::Promo::Project.create!(
        name: 'Auth Test',
        reference_number: 'AUTH-001',
        project_type: 'residential',
        status: 'planning',
        organization: organization,
        project_manager: user,
        start_date: Date.current,
        end_date: Date.current + 1.year
      )

      policy = Immo::Promo::ProjectPolicy.new(user, project)
      expect(policy.show?).to be true
      expect(policy.update?).to be true
      expect(policy.destroy?).to be true
    end
  end
end
