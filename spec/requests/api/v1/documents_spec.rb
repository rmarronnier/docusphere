require 'rails_helper'

RSpec.describe "API V1 Documents", type: :request do
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
  
  describe "GET /api/v1/documents" do
    let!(:documents) {
      3.times.map do |i|
        create(:document, 
          title: "Document #{i}",
          space: space,
          uploaded_by: user
        )
      end
    }
    
    it "returns a list of documents" do
      get "/api/v1/documents", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["documents"].count).to eq(3)
      expect(json["meta"]["total"]).to eq(3)
      expect(json["meta"]["page"]).to eq(1)
    end
    
    it "paginates results" do
      get "/api/v1/documents", params: { page: 1, per_page: 2 }, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["documents"].count).to eq(2)
      expect(json["meta"]["total"]).to eq(3)
      expect(json["meta"]["pages"]).to eq(2)
    end
    
    it "filters by space" do
      other_space = create(:space, organization: organization)
      create(:document, space: other_space)
      
      get "/api/v1/documents", params: { space_id: space.id }, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["documents"].count).to eq(3)
      expect(json["documents"].all? { |d| d["space_id"] == space.id }).to be true
    end
    
    it "searches by query" do
      create(:document, title: "Special Report", space: space)
      
      get "/api/v1/documents", params: { q: "Special" }, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["documents"].count).to eq(1)
      expect(json["documents"].first["title"]).to eq("Special Report")
    end
    
    it "requires authentication" do
      get "/api/v1/documents"
      
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
    end
  end
  
  describe "GET /api/v1/documents/:id" do
    let(:document) { create(:document, space: space, uploaded_by: user) }
    
    it "returns document details" do
      get "/api/v1/documents/#{document.id}", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["document"]["id"]).to eq(document.id)
      expect(json["document"]["title"]).to eq(document.title)
      expect(json["document"]["user"]["id"]).to eq(user.id)
      expect(json["document"]["space"]["id"]).to eq(space.id)
    end
    
    it "includes metadata and tags" do
      tag = create(:tag, name: "Important")
      document.tags << tag
      document.metadata.create!(key: "client", value: "ABC Corp")
      
      get "/api/v1/documents/#{document.id}", headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["document"]["tags"]).to include(hash_including("name" => "Important"))
      expect(json["document"]["metadata"]).to include(hash_including("key" => "client", "value" => "ABC Corp"))
    end
    
    it "returns 404 for non-existent document" do
      get "/api/v1/documents/999999", headers: valid_headers
      
      expect(response).to have_http_status(:not_found)
    end
    
    it "returns 403 for unauthorized document" do
      other_org = create(:organization)
      other_space = create(:space, organization: other_org)
      other_doc = create(:document, space: other_space)
      
      get "/api/v1/documents/#{other_doc.id}", headers: valid_headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe "POST /api/v1/documents" do
    let(:valid_params) {
      {
        document: {
          title: "New Document",
          description: "Test description",
          space_id: space.id,
          file: fixture_file_upload("spec/fixtures/test_document.pdf", "application/pdf")
        }
      }
    }
    
    it "creates a new document" do
      expect {
        post "/api/v1/documents", params: valid_params, headers: valid_headers.except("Content-Type")
      }.to change(Document, :count).by(1)
      
      expect(response).to have_http_status(:created)
      
      json = JSON.parse(response.body)
      expect(json["document"]["title"]).to eq("New Document")
      expect(json["document"]["processing_status"]).to eq("pending")
    end
    
    it "creates document with metadata" do
      params = valid_params.deep_merge(
        document: {
          metadata_attributes: [
            { key: "department", value: "Sales" },
            { key: "year", value: "2024" }
          ]
        }
      )
      
      post "/api/v1/documents", params: params, headers: valid_headers.except("Content-Type")
      
      document = Document.last
      expect(document.metadata.pluck(:key, :value)).to contain_exactly(
        ["department", "Sales"],
        ["year", "2024"]
      )
    end
    
    it "returns validation errors" do
      invalid_params = { document: { title: "" } }
      
      post "/api/v1/documents", params: invalid_params, headers: valid_headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      
      json = JSON.parse(response.body)
      expect(json["errors"]["title"]).to include("can't be blank")
      expect(json["errors"]["file"]).to include("can't be blank")
    end
    
    it "handles file upload errors" do
      params = valid_params.deep_merge(
        document: {
          file: fixture_file_upload("spec/fixtures/malformed.pdf", "application/pdf")
        }
      )
      
      post "/api/v1/documents", params: params, headers: valid_headers.except("Content-Type")
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]["file"]).to be_present
    end
  end
  
  describe "PATCH /api/v1/documents/:id" do
    let(:document) { create(:document, space: space, uploaded_by: user) }
    let(:update_params) {
      {
        document: {
          title: "Updated Title",
          description: "Updated description"
        }
      }
    }
    
    it "updates the document" do
      patch "/api/v1/documents/#{document.id}", params: update_params, headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["document"]["title"]).to eq("Updated Title")
      expect(json["document"]["description"]).to eq("Updated description")
      
      document.reload
      expect(document.title).to eq("Updated Title")
    end
    
    it "updates tags" do
      tag1 = create(:tag, name: "Tag1", organization: organization)
      tag2 = create(:tag, name: "Tag2", organization: organization)
      
      params = { document: { tag_ids: [tag1.id, tag2.id] } }
      
      patch "/api/v1/documents/#{document.id}", params: params, headers: valid_headers
      
      document.reload
      expect(document.tags.pluck(:name)).to contain_exactly("Tag1", "Tag2")
    end
    
    it "requires appropriate permissions" do
      other_user = create(:user, organization: organization)
      document.update!(user: other_user)
      
      patch "/api/v1/documents/#{document.id}", params: update_params, headers: valid_headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe "DELETE /api/v1/documents/:id" do
    let!(:document) { create(:document, space: space, uploaded_by: user) }
    
    it "deletes the document" do
      expect {
        delete "/api/v1/documents/#{document.id}", headers: valid_headers
      }.to change(Document, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
    
    it "requires ownership" do
      other_user = create(:user, organization: organization)
      document.update!(user: other_user)
      
      delete "/api/v1/documents/#{document.id}", headers: valid_headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe "POST /api/v1/documents/:id/share" do
    let(:document) { create(:document, space: space, uploaded_by: user) }
    let(:recipient) { create(:user, organization: organization) }
    let(:share_params) {
      {
        share: {
          user_ids: [recipient.id],
          permission: "read",
          expires_at: 7.days.from_now,
          message: "Please review this document"
        }
      }
    }
    
    it "creates document shares" do
      expect {
        post "/api/v1/documents/#{document.id}/share", params: share_params, headers: valid_headers
      }.to change(DocumentShare, :count).by(1)
      
      expect(response).to have_http_status(:created)
      
      json = JSON.parse(response.body)
      expect(json["shares"].count).to eq(1)
      expect(json["shares"].first["user"]["id"]).to eq(recipient.id)
      expect(json["shares"].first["permission"]).to eq("read")
    end
    
    it "sends notification to recipients" do
      expect {
        post "/api/v1/documents/#{document.id}/share", params: share_params, headers: valid_headers
      }.to change(ActionMailer::Base.deliveries, :count).by(1)
      
      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(recipient.email)
      expect(mail.subject).to include("shared a document")
    end
    
    it "creates public share link" do
      params = {
        share: {
          public: true,
          permission: "read",
          expires_at: 3.days.from_now,
          password: "secret123"
        }
      }
      
      post "/api/v1/documents/#{document.id}/share", params: params, headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["share"]["public"]).to be true
      expect(json["share"]["url"]).to be_present
      expect(json["share"]["password_protected"]).to be true
    end
  end
  
  describe "GET /api/v1/documents/:id/download" do
    let(:document) { create(:document, space: space, uploaded_by: user) }
    
    before do
      document.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/test_document.pdf")),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
    end
    
    it "downloads the document file" do
      get "/api/v1/documents/#{document.id}/download", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("test.pdf")
    end
    
    it "tracks download activity" do
      expect {
        get "/api/v1/documents/#{document.id}/download", headers: valid_headers
      }.to change { document.activities.count }.by(1)
      
      activity = document.activities.last
      expect(activity.action).to eq("downloaded")
      expect(activity.user).to eq(user)
    end
    
    it "respects download permissions" do
      document.update!(download_enabled: false)
      
      get "/api/v1/documents/#{document.id}/download", headers: valid_headers
      
      expect(response).to have_http_status(:forbidden)
    end
  end
  
  describe "POST /api/v1/documents/:id/versions" do
    let(:document) { create(:document, space: space, uploaded_by: user) }
    let(:version_params) {
      {
        version: {
          file: fixture_file_upload("spec/fixtures/test_document_v2.pdf", "application/pdf"),
          notes: "Updated content with corrections"
        }
      }
    }
    
    it "creates a new version" do
      expect {
        post "/api/v1/documents/#{document.id}/versions", 
             params: version_params, 
             headers: valid_headers.except("Content-Type")
      }.to change { document.versions.count }.by(1)
      
      expect(response).to have_http_status(:created)
      
      json = JSON.parse(response.body)
      expect(json["version"]["version_number"]).to eq(2)
      expect(json["version"]["notes"]).to eq("Updated content with corrections")
    end
    
    it "maintains version history" do
      # Create multiple versions
      3.times do |i|
        post "/api/v1/documents/#{document.id}/versions",
             params: {
               version: {
                 file: fixture_file_upload("spec/fixtures/test_document.pdf", "application/pdf"),
                 notes: "Version #{i + 2}"
               }
             },
             headers: valid_headers.except("Content-Type")
      end
      
      get "/api/v1/documents/#{document.id}/versions", headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["versions"].count).to eq(4) # Original + 3 new
      expect(json["versions"].first["version_number"]).to eq(4)
      expect(json["versions"].last["version_number"]).to eq(1)
    end
  end
  
  describe "POST /api/v1/documents/bulk" do
    let(:bulk_params) {
      {
        documents: [
          {
            title: "Bulk Doc 1",
            space_id: space.id,
            file: fixture_file_upload("spec/fixtures/test_document.pdf", "application/pdf")
          },
          {
            title: "Bulk Doc 2",
            space_id: space.id,
            file: fixture_file_upload("spec/fixtures/test_document.pdf", "application/pdf")
          }
        ]
      }
    }
    
    it "creates multiple documents" do
      expect {
        post "/api/v1/documents/bulk", 
             params: bulk_params,
             headers: valid_headers.except("Content-Type")
      }.to change(Document, :count).by(2)
      
      expect(response).to have_http_status(:created)
      
      json = JSON.parse(response.body)
      expect(json["documents"].count).to eq(2)
      expect(json["documents"].map { |d| d["title"] }).to contain_exactly("Bulk Doc 1", "Bulk Doc 2")
    end
    
    it "handles partial failures" do
      params = {
        documents: [
          { title: "Valid Doc", space_id: space.id, file: fixture_file_upload("spec/fixtures/test_document.pdf") },
          { title: "", space_id: space.id } # Invalid - missing file and title
        ]
      }
      
      post "/api/v1/documents/bulk", 
           params: params,
           headers: valid_headers.except("Content-Type")
      
      expect(response).to have_http_status(:multi_status)
      
      json = JSON.parse(response.body)
      expect(json["succeeded"].count).to eq(1)
      expect(json["failed"].count).to eq(1)
      expect(json["failed"].first["errors"]).to be_present
    end
  end
end