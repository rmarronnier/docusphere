require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    context 'when user is not signed in' do
      it 'renders the landing page' do
        get :index
        expect(response).to render_template('landing')
      end
      
      it 'does not require authentication' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'when user is signed in' do
      let(:user) { create(:user) }
      
      before do
        sign_in user
      end
      
      it 'renders the dashboard' do
        get :index
        expect(response).to render_template('dashboard')
      end
      
      it 'loads pending documents' do
        draft_doc = create(:document, status: 'draft', uploaded_by: user)
        locked_doc = create(:document, status: 'locked', locked_by: user)
        
        get :index
        
        expect(assigns(:pending_documents)).to include(draft_doc)
        expect(assigns(:pending_documents)).to include(locked_doc)
      end
      
      it 'loads recent activities' do
        recent_doc = create(:document, uploaded_by: user, created_at: 1.hour.ago)
        old_doc = create(:document, uploaded_by: user, created_at: 2.weeks.ago)
        
        get :index
        
        expect(assigns(:recent_activities)).to include(recent_doc)
        expect(assigns(:recent_activities)).not_to include(old_doc)
      end
      
      it 'loads dashboard statistics' do
        create_list(:document, 3, uploaded_by: user)
        
        get :index
        
        stats = assigns(:statistics)
        expect(stats).to be_a(Hash)
        expect(stats[:total_documents]).to be_present
        expect(stats[:storage_used]).to be_present
      end
      
      it 'successfully renders without errors' do
        # Ce test aurait détecté l'erreur NoMethodError
        expect { get :index }.not_to raise_error
        expect(response).to have_http_status(:success)
      end
      
      it 'loads all dashboard data without errors' do
        # Test complet qui vérifie que toutes les méthodes existent
        create(:document, uploaded_by: user, status: 'draft')
        create(:document_validation, validator: user, status: 'pending')
        create(:document_share, shared_with: user)
        
        get :index
        
        expect(response).to have_http_status(:success)
        expect(assigns(:pending_documents)).not_to be_nil
        expect(assigns(:recent_activities)).not_to be_nil
        expect(assigns(:statistics)).to include(
          :total_documents,
          :pending_validations,
          :shared_documents,
          :storage_used
        )
      end
      
      it 'handles users without any documents gracefully' do
        # S'assure que le dashboard fonctionne même sans données
        get :index
        
        expect(response).to have_http_status(:success)
        expect(assigns(:statistics)[:total_documents]).to eq(0)
        expect(assigns(:statistics)[:pending_validations]).to eq(0)
        expect(assigns(:statistics)[:shared_documents]).to eq(0)
      end
      
      it 'loads widgets based on user profile' do
        get :index
        
        widgets = assigns(:widgets)
        expect(widgets).to include(:pending_documents)
        expect(widgets).to include(:recent_activity)
        expect(widgets).to include(:quick_actions)
        expect(widgets).to include(:statistics)
      end
      
      context 'with different user profiles' do
        it 'loads direction-specific widgets' do
          profile = create(:profile, user: user, profile_type: 'direction', is_active: true)
          allow(user).to receive(:active_profile).and_return(profile)
          
          get :index
          
          widgets = assigns(:widgets)
          expect(widgets).to include(:validation_queue)
          expect(widgets).to include(:compliance_alerts)
          expect(widgets).to include(:team_activity)
        end
        
        it 'loads chef_projet-specific widgets' do
          profile = create(:profile, user: user, profile_type: 'chef_projet', is_active: true)
          allow(user).to receive(:active_profile).and_return(profile)
          
          get :index
          
          widgets = assigns(:widgets)
          expect(widgets).to include(:project_documents)
          expect(widgets).to include(:task_deadlines)
          expect(widgets).to include(:team_resources)
        end
        
        it 'loads commercial-specific widgets' do
          profile = create(:profile, user: user, profile_type: 'commercial', is_active: true)
          allow(user).to receive(:active_profile).and_return(profile)
          
          get :index
          
          widgets = assigns(:widgets)
          expect(widgets).to include(:client_documents)
          expect(widgets).to include(:proposals_pending)
          expect(widgets).to include(:contract_status)
        end
      end
    end
  end
  
  describe 'private methods' do
    let(:user) { create(:user) }
    let(:controller) { described_class.new }
    
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end
    
    describe '#calculate_storage_used' do
      it 'formats storage size correctly' do
        # Mock document with file
        doc = create(:document, uploaded_by: user)
        allow(doc.file).to receive_message_chain(:blob, :byte_size).and_return(1_500_000)
        allow(user).to receive_message_chain(:documents, :joins, :sum).and_return(1_500_000)
        
        result = controller.send(:calculate_storage_used, user)
        expect(result).to eq('1.4 MB')
      end
      
      it 'handles different size ranges' do
        allow(user).to receive_message_chain(:documents, :joins, :sum).and_return(500)
        expect(controller.send(:calculate_storage_used, user)).to eq('500 B')
        
        allow(user).to receive_message_chain(:documents, :joins, :sum).and_return(5_000)
        expect(controller.send(:calculate_storage_used, user)).to eq('4.9 KB')
        
        allow(user).to receive_message_chain(:documents, :joins, :sum).and_return(5_000_000_000)
        expect(controller.send(:calculate_storage_used, user)).to eq('4.66 GB')
      end
    end
    
    describe '#widgets_for_profile' do
      it 'returns base widgets for users without profile' do
        allow(user).to receive(:active_profile).and_return(nil)
        
        widgets = controller.send(:widgets_for_profile, user)
        expect(widgets).to include(:pending_documents)
        expect(widgets).to include(:recent_activity)
        expect(widgets).to include(:quick_actions)
        expect(widgets).to include(:statistics)
      end
      
      it 'adds profile-specific widgets' do
        profile = create(:profile, user: user, profile_type: 'finance', is_active: true)
        allow(user).to receive(:active_profile).and_return(profile)
        
        widgets = controller.send(:widgets_for_profile, user)
        expect(widgets).to include(:invoices_pending)
        expect(widgets).to include(:budget_alerts)
        expect(widgets).to include(:expense_reports)
      end
      
      it 'returns unique widgets' do
        profile = create(:profile, user: user, profile_type: 'direction', is_active: true)
        allow(user).to receive(:active_profile).and_return(profile)
        
        widgets = controller.send(:widgets_for_profile, user)
        expect(widgets).to eq(widgets.uniq)
      end
    end
  end
end