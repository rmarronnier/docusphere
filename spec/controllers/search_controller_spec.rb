require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  
  before do
    sign_in user
  end

  describe "GET #index" do
    let!(:document1) { create(:document, title: "Important Contract", space: space, uploaded_by: user) }
    let!(:document2) { create(:document, title: "Meeting Notes", description: "Contract review meeting", space: space, uploaded_by: user) }
    let!(:document3) { create(:document, title: "Invoice", space: space, uploaded_by: user) }
    let!(:other_org_doc) { create(:document, title: "Contract Other Org") }
    
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
    
    context "with search query" do
      it "finds documents by title" do
        get :index, params: { q: "Contract" }
        expect(assigns(:documents)).to include(document1)
        expect(assigns(:documents)).not_to include(document3)
        expect(assigns(:documents)).not_to include(other_org_doc) # Policy scope
      end
      
      it "finds documents by description" do
        get :index, params: { q: "review" }
        expect(assigns(:documents)).to include(document2)
        expect(assigns(:documents)).not_to include(document1)
      end
      
      it "returns empty results for no matches" do
        get :index, params: { q: "NonExistentDocument" }
        expect(assigns(:documents)).to be_empty
      end
    end
    
    context "without search query" do
      it "returns no documents" do
        get :index
        expect(assigns(:documents)).to be_empty
      end
    end
  end

  describe "GET #suggestions" do
    let!(:document1) { create(:document, title: "Project Alpha Report", space: space, uploaded_by: user) }
    let!(:document2) { create(:document, title: "Project Beta Analysis", space: space, uploaded_by: user) }
    let!(:tag) { create(:tag, name: "project-management") }
    let!(:document3) { create(:document, title: "Budget Document", space: space, uploaded_by: user, tags: [tag]) }
    
    before do
      # Create metadata
      document1.metadata.create!(key: "project_name", value: "Alpha Project 2024")
    end
    
    it "returns JSON suggestions" do
      get :suggestions, params: { q: "Project" }, format: :json
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(/json/)
    end
    
    it "finds documents by title" do
      get :suggestions, params: { q: "Alpha" }, format: :json
      json = JSON.parse(response.body)
      expect(json['suggestions'].length).to eq(1)
      expect(json['suggestions'].first['title']).to eq("Project Alpha Report")
    end
    
    it "finds documents by metadata" do
      get :suggestions, params: { q: "2024" }, format: :json
      json = JSON.parse(response.body)
      expect(json['suggestions']).not_to be_empty
      expect(json['suggestions'].map { |s| s['id'] }).to include(document1.id)
    end
    
    it "finds documents by tag" do
      get :suggestions, params: { q: "management" }, format: :json
      json = JSON.parse(response.body)
      expect(json['suggestions']).not_to be_empty
      expect(json['suggestions'].map { |s| s['id'] }).to include(document3.id)
    end
    
    it "returns empty suggestions for short queries" do
      get :suggestions, params: { q: "a" }, format: :json
      json = JSON.parse(response.body)
      expect(json['suggestions']).to be_empty
    end
    
    it "limits suggestions to 10" do
      15.times do |i|
        create(:document, title: "Test Document #{i}", space: space, uploaded_by: user)
      end
      
      get :suggestions, params: { q: "Test" }, format: :json
      json = JSON.parse(response.body)
      expect(json['suggestions'].length).to eq(10)
    end
    
    it "includes required fields in suggestions" do
      get :suggestions, params: { q: "Project" }, format: :json
      json = JSON.parse(response.body)
      suggestion = json['suggestions'].first
      
      expect(suggestion).to have_key('id')
      expect(suggestion).to have_key('title')
      expect(suggestion).to have_key('description')
      expect(suggestion).to have_key('type')
      expect(suggestion).to have_key('space')
      expect(suggestion).to have_key('url')
    end
  end
end