require 'rails_helper'

RSpec.describe Immo::Promo::BudgetsController, type: :controller do
  routes { ImmoPromo::Engine.routes }
  
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:budget) { create(:immo_promo_budget, project: project) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns budgets' do
      budget # create it
      get :index, params: { project_id: project.id }, format: :json
      expect(assigns(:budgets)).to include(budget)
    end

    it 'filters by status when provided' do
      approved_budget = create(:immo_promo_budget, project: project, status: 'approved', version: '2.0')
      draft_budget = create(:immo_promo_budget, project: project, status: 'draft', version: '3.0')
      
      get :index, params: { project_id: project.id, status: 'approved' }, format: :json
      expect(assigns(:budgets)).to include(approved_budget)
      expect(assigns(:budgets)).not_to include(draft_budget)
    end

    it 'calculates budget totals' do
      get :index, params: { project_id: project.id }, format: :json
      expect(assigns(:total_approved_budget)).to be_present
      expect(assigns(:total_spent)).to be_present
      expect(assigns(:budget_utilization)).to be_present
    end
  end

  describe 'GET #show' do

    it 'returns a success response' do
      get :show, params: { project_id: project.id, id: budget.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns the requested budget' do
      get :show, params: { project_id: project.id, id: budget.id }, format: :json
      expect(assigns(:budget)).to eq(budget)
    end

    it 'assigns budget lines' do
      create(:immo_promo_budget_line, budget: budget)
      get :show, params: { project_id: project.id, id: budget.id }, format: :json
      expect(assigns(:budget_lines)).to be_present
    end

    it 'calculates budget summary' do
      get :show, params: { project_id: project.id, id: budget.id }, format: :json
      expect(assigns(:budget_summary)).to be_present
      expect(assigns(:budget_summary)).to have_key(:total_planned)
      expect(assigns(:budget_summary)).to have_key(:total_spent)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new, params: { project_id: project.id }, format: :json
      expect(response).to be_successful
    end

    it 'assigns a new budget' do
      get :new, params: { project_id: project.id }, format: :json
      expect(assigns(:budget)).to be_a_new(Immo::Promo::Budget)
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { project_id: project.id, id: budget.id }, format: :json
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_attributes) do
        {
          name: 'New Budget',
          status: 'draft',
          total_amount_cents: 1_000_000_00,
          version: '2.0'
        }
      end

      it 'creates a new Budget' do
        expect {
          post :create, params: { project_id: project.id, immo_promo_budget: valid_attributes }
        }.to change(Immo::Promo::Budget, :count).by(1)
      end

      it 'redirects to the created budget' do
        post :create, params: { project_id: project.id, immo_promo_budget: valid_attributes }
        expect(response).to redirect_to("/immo/promo/projects/#{project.id}/budgets/#{Immo::Promo::Budget.last.id}")
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '', version: '' }
      end

      it 'returns an unprocessable entity response' do
        post :create, params: { project_id: project.id, immo_promo_budget: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Budget Name' }
      end

      it 'updates the requested budget' do
        put :update, params: { project_id: project.id, id: budget.id, immo_promo_budget: new_attributes }
        budget.reload
        expect(budget.name).to eq('Updated Budget Name')
      end

      it 'redirects to the budget' do
        put :update, params: { project_id: project.id, id: budget.id, immo_promo_budget: new_attributes }
        expect(response).to redirect_to("/immo/promo/projects/#{project.id}/budgets/#{budget.id}")
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested budget when allowed' do
      budget # create it
      
      expect {
        delete :destroy, params: { project_id: project.id, id: budget.id }
      }.to change(Immo::Promo::Budget, :count).by(-1)
    end

    it 'redirects to the budgets list' do
      delete :destroy, params: { project_id: project.id, id: budget.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/budgets")
    end

    it 'shows error when budget cannot be deleted' do
      # Créer des budget_lines pour empêcher la suppression
      create(:immo_promo_budget_line, budget: budget)
      delete :destroy, params: { project_id: project.id, id: budget.id }
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #approve' do
    it 'approves the budget when allowed' do
      post :approve, params: { project_id: project.id, id: budget.id }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/budgets/#{budget.id}")
      expect(flash[:notice]).to be_present
    end

    it 'shows error when budget cannot be approved' do
      # Déjà approuvé via Validatable
      budget.request_validation(requester: user, validators: [user])
      budget.validate_by!(user, approved: true)
      
      post :approve, params: { project_id: project.id, id: budget.id }
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #reject' do
    it 'rejects the budget when allowed' do
      # Créer une demande de validation pour pouvoir la rejeter
      budget.request_validation(requester: user, validators: [user])
      
      post :reject, params: { 
        project_id: project.id, 
        id: budget.id, 
        reason: 'Test rejection' 
      }
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/budgets/#{budget.id}")
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST #duplicate' do
    it 'duplicates the budget successfully' do
      post :duplicate, params: { project_id: project.id, id: budget.id }
      new_budget = Immo::Promo::Budget.order(:created_at).last
      expect(response).to redirect_to("/immo/promo/projects/#{project.id}/budgets/#{new_budget.id}/edit")
      expect(flash[:notice]).to be_present
    end
  end
end