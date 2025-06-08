require 'rails_helper'

RSpec.describe "API V1 Search", type: :request do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:space) { create(:space, organization: organization) }
  let(:valid_headers) {
    {
      "Authorization" => "Bearer #{user.authentication_token}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  }
  
  before do
    # Créer des documents de test
    @doc1 = create(:document, 
      title: "Contract Agreement 2024",
      description: "Annual service contract",
      content: "This agreement defines the terms of service",
      space: space
    )
    
    @doc2 = create(:document,
      title: "Invoice INV-2024-001",
      description: "January invoice for services",
      content: "Total amount due: $5,000",
      space: space
    )
    
    @doc3 = create(:document,
      title: "Project Report Q1",
      description: "Quarterly performance report",
      content: "Excellent performance this quarter with 20% growth",
      space: space
    )
    
    # Ajouter des tags
    tag_urgent = create(:tag, name: "Urgent", organization: organization)
    tag_finance = create(:tag, name: "Finance", organization: organization)
    
    @doc1.tags << tag_urgent
    @doc2.tags << [tag_finance, tag_urgent]
    @doc3.tags << tag_finance
    
    # Ajouter des métadonnées
    @doc1.metadata.create!(key: "client", value: "ABC Corporation")
    @doc2.metadata.create!(key: "amount", value: "5000")
    @doc2.metadata.create!(key: "status", value: "paid")
  end
  
  describe "GET /api/v1/search" do
    it "searches documents by title" do
      get "/api/v1/search", params: { q: "Contract" }, headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["results"].count).to eq(1)
      expect(json["results"].first["title"]).to eq("Contract Agreement 2024")
      expect(json["meta"]["total"]).to eq(1)
      expect(json["meta"]["query"]).to eq("Contract")
    end
    
    it "searches across multiple fields" do
      get "/api/v1/search", params: { q: "2024" }, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["results"].count).to eq(2)
      titles = json["results"].map { |r| r["title"] }
      expect(titles).to contain_exactly("Contract Agreement 2024", "Invoice INV-2024-001")
    end
    
    it "highlights matching terms" do
      get "/api/v1/search", params: { q: "invoice", highlight: true }, headers: valid_headers
      
      json = JSON.parse(response.body)
      result = json["results"].first
      expect(result["highlights"]["title"]).to include("<mark>Invoice</mark>")
      expect(result["highlights"]["description"]).to include("<mark>invoice</mark>")
    end
    
    it "supports fuzzy search" do
      get "/api/v1/search", params: { q: "invioce", fuzzy: true }, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["results"].count).to eq(1)
      expect(json["results"].first["title"]).to include("Invoice")
      expect(json["meta"]["corrected_query"]).to eq("invoice")
    end
  end
  
  describe "POST /api/v1/search/advanced" do
    let(:advanced_params) {
      {
        filters: {
          title: { contains: "2024" },
          created_at: { 
            from: 1.week.ago.iso8601,
            to: Date.tomorrow.iso8601
          },
          tags: ["Finance"],
          metadata: [
            { key: "status", value: "paid", operator: "equals" }
          ]
        },
        sort: { field: "created_at", order: "desc" },
        page: 1,
        per_page: 20
      }
    }
    
    it "performs advanced multi-criteria search" do
      post "/api/v1/search/advanced", params: advanced_params.to_json, headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["results"].count).to eq(1)
      expect(json["results"].first["title"]).to eq("Invoice INV-2024-001")
    end
    
    it "filters by tags with AND operator" do
      params = {
        filters: {
          tags: ["Urgent", "Finance"],
          tags_operator: "AND"
        }
      }
      
      post "/api/v1/search/advanced", params: params.to_json, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["results"].count).to eq(1)
      expect(json["results"].first["id"]).to eq(@doc2.id)
    end
    
    it "filters by tags with OR operator" do
      params = {
        filters: {
          tags: ["Urgent", "Finance"],
          tags_operator: "OR"
        }
      }
      
      post "/api/v1/search/advanced", params: params.to_json, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["results"].count).to eq(3)
    end
    
    it "filters by metadata conditions" do
      params = {
        filters: {
          metadata: [
            { key: "amount", value: "1000", operator: "greater_than" }
          ]
        }
      }
      
      post "/api/v1/search/advanced", params: params.to_json, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["results"].count).to eq(1)
      expect(json["results"].first["id"]).to eq(@doc2.id)
    end
    
    it "combines multiple filter conditions" do
      params = {
        filters: {
          query: "2024",
          tags: ["Finance"],
          space_ids: [space.id],
          file_types: ["pdf"]
        },
        operator: "AND"
      }
      
      post "/api/v1/search/advanced", params: params.to_json, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["results"]).not_to be_empty
    end
  end
  
  describe "GET /api/v1/search/suggestions" do
    it "provides search suggestions based on partial input" do
      get "/api/v1/search/suggestions", params: { q: "inv" }, headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["suggestions"]).to include(
        hash_including(
          "type" => "document",
          "title" => "Invoice INV-2024-001",
          "category" => "Documents"
        )
      )
    end
    
    it "includes tag suggestions" do
      get "/api/v1/search/suggestions", params: { q: "urg" }, headers: valid_headers
      
      json = JSON.parse(response.body)
      tag_suggestions = json["suggestions"].select { |s| s["type"] == "tag" }
      expect(tag_suggestions).not_to be_empty
      expect(tag_suggestions.first["title"]).to eq("Urgent")
    end
    
    it "includes recent searches" do
      # Simuler des recherches récentes
      user.search_queries.create!(query: "urgent documents", performed_at: 1.hour.ago)
      user.search_queries.create!(query: "urgent finance", performed_at: 2.hours.ago)
      
      get "/api/v1/search/suggestions", params: { q: "urg" }, headers: valid_headers
      
      json = JSON.parse(response.body)
      recent_suggestions = json["suggestions"].select { |s| s["type"] == "recent" }
      expect(recent_suggestions.map { |s| s["title"] }).to include("urgent documents", "urgent finance")
    end
    
    it "limits number of suggestions" do
      # Créer beaucoup de documents
      20.times { |i| create(:document, title: "Invoice #{i}", space: space) }
      
      get "/api/v1/search/suggestions", params: { q: "inv", limit: 5 }, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["suggestions"].count).to eq(5)
    end
  end
  
  describe "POST /api/v1/search/save" do
    let(:save_params) {
      {
        search: {
          name: "Monthly Finance Docs",
          query: "finance 2024",
          filters: {
            tags: ["Finance"],
            created_at: { from: Date.today.beginning_of_month.iso8601 }
          },
          notify_new_results: true
        }
      }
    }
    
    it "saves a search query" do
      expect {
        post "/api/v1/search/save", params: save_params.to_json, headers: valid_headers
      }.to change { user.saved_searches.count }.by(1)
      
      expect(response).to have_http_status(:created)
      
      json = JSON.parse(response.body)
      expect(json["search"]["name"]).to eq("Monthly Finance Docs")
      expect(json["search"]["notify_new_results"]).to be true
    end
    
    it "validates saved search parameters" do
      invalid_params = { search: { name: "", query: "" } }
      
      post "/api/v1/search/save", params: invalid_params.to_json, headers: valid_headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      
      json = JSON.parse(response.body)
      expect(json["errors"]["name"]).to include("can't be blank")
    end
  end
  
  describe "GET /api/v1/search/saved" do
    before do
      user.saved_searches.create!(
        name: "Important Docs",
        query: "urgent",
        filters: { tags: ["Urgent"] }
      )
      
      user.saved_searches.create!(
        name: "Finance Reports",
        query: "finance report",
        filters: { tags: ["Finance"] }
      )
    end
    
    it "returns user's saved searches" do
      get "/api/v1/search/saved", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["searches"].count).to eq(2)
      expect(json["searches"].map { |s| s["name"] }).to contain_exactly("Important Docs", "Finance Reports")
    end
    
    it "executes a saved search" do
      saved_search = user.saved_searches.first
      
      get "/api/v1/search/saved/#{saved_search.id}/execute", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["results"]).not_to be_empty
      expect(json["meta"]["saved_search_id"]).to eq(saved_search.id)
    end
  end
  
  describe "GET /api/v1/search/facets" do
    before do
      # Créer plus de documents pour les facettes
      5.times do |i|
        doc = create(:document, 
          title: "Document #{i}",
          space: space,
          created_at: i.days.ago
        )
        doc.file.attach(
          io: StringIO.new("content"),
          filename: "doc#{i}.#{['pdf', 'docx', 'xlsx'].sample}",
          content_type: ['application/pdf', 'application/vnd.ms-word', 'application/vnd.ms-excel'].sample
        )
      end
    end
    
    it "returns search facets" do
      get "/api/v1/search/facets", params: { q: "" }, headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["facets"]).to include("tags", "file_types", "date_ranges", "spaces")
      
      # Vérifier les comptes de tags
      tag_facet = json["facets"]["tags"]
      expect(tag_facet).to include(
        hash_including("value" => "Finance", "count" => 2),
        hash_including("value" => "Urgent", "count" => 2)
      )
    end
    
    it "updates facets based on current filters" do
      get "/api/v1/search/facets", 
          params: { q: "2024", filters: { tags: ["Finance"] } }, 
          headers: valid_headers
      
      json = JSON.parse(response.body)
      
      # Les comptes doivent être mis à jour selon les filtres
      tag_facet = json["facets"]["tags"]
      urgent_facet = tag_facet.find { |f| f["value"] == "Urgent" }
      expect(urgent_facet["count"]).to eq(1) # Seulement doc2 a Finance + Urgent + 2024
    end
  end
  
  describe "GET /api/v1/search/export" do
    it "exports search results" do
      get "/api/v1/search/export", 
          params: { q: "2024", format: "csv" }, 
          headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      
      csv = CSV.parse(response.body, headers: true)
      expect(csv.count).to eq(2)
      expect(csv.headers).to include("Title", "Description", "Created At", "Tags")
    end
    
    it "exports with selected columns" do
      get "/api/v1/search/export",
          params: { 
            q: "2024", 
            format: "json",
            columns: ["title", "tags", "metadata"]
          },
          headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["documents"].first.keys).to contain_exactly("id", "title", "tags", "metadata")
    end
    
    it "limits export size" do
      # Créer beaucoup de documents
      100.times { create(:document, title: "Export test", space: space) }
      
      get "/api/v1/search/export",
          params: { q: "Export", format: "csv", limit: 50 },
          headers: valid_headers
      
      csv = CSV.parse(response.body, headers: true)
      expect(csv.count).to eq(50)
    end
  end
  
  describe "GET /api/v1/search/history" do
    before do
      # Créer un historique de recherche
      user.search_queries.create!([
        { query: "contract", performed_at: 1.hour.ago, results_count: 5 },
        { query: "invoice 2024", performed_at: 2.hours.ago, results_count: 3 },
        { query: "report", performed_at: 1.day.ago, results_count: 10 }
      ])
    end
    
    it "returns search history" do
      get "/api/v1/search/history", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["history"].count).to eq(3)
      expect(json["history"].first["query"]).to eq("contract")
    end
    
    it "clears search history" do
      expect {
        delete "/api/v1/search/history", headers: valid_headers
      }.to change { user.search_queries.count }.to(0)
      
      expect(response).to have_http_status(:no_content)
    end
  end
end