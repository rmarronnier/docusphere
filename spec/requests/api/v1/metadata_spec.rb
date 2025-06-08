require 'rails_helper'

RSpec.describe "API V1 Metadata", type: :request do
  let(:user) { create(:user, role: 'admin') }
  let(:organization) { user.organization }
  let(:valid_headers) {
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  }
  
  before do
    sign_in user
  end
  
  describe "GET /api/v1/metadata/templates" do
    let!(:templates) {
      [
        create(:metadata_template, 
          name: "Invoice Template",
          organization: organization,
          fields: [
            { name: "invoice_number", label: "Invoice Number", type: "string", required: true },
            { name: "amount", label: "Amount", type: "number", required: true },
            { name: "due_date", label: "Due Date", type: "date", required: false }
          ]
        ),
        create(:metadata_template,
          name: "Contract Template",
          organization: organization,
          fields: [
            { name: "client_name", label: "Client Name", type: "string", required: true },
            { name: "contract_value", label: "Contract Value", type: "number", required: true }
          ]
        )
      ]
    }
    
    it "returns all metadata templates" do
      get "/api/v1/metadata/templates", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["templates"].count).to eq(2)
      expect(json["templates"].map { |t| t["name"] }).to contain_exactly("Invoice Template", "Contract Template")
    end
    
    it "includes field definitions" do
      get "/api/v1/metadata/templates", headers: valid_headers
      
      json = JSON.parse(response.body)
      invoice_template = json["templates"].find { |t| t["name"] == "Invoice Template" }
      
      expect(invoice_template["fields"].count).to eq(3)
      expect(invoice_template["fields"].first).to include(
        "name" => "invoice_number",
        "label" => "Invoice Number",
        "type" => "string",
        "required" => true
      )
    end
  end
  
  describe "POST /api/v1/metadata/templates" do
    let(:valid_params) {
      {
        template: {
          name: "Purchase Order",
          description: "Template for purchase orders",
          fields_attributes: [
            {
              name: "po_number",
              label: "PO Number",
              field_type: "string",
              required: true,
              validation_rules: { pattern: "^PO-\\d{6}$" }
            },
            {
              name: "vendor",
              label: "Vendor",
              field_type: "string",
              required: true
            },
            {
              name: "total_amount",
              label: "Total Amount",
              field_type: "number",
              required: true,
              validation_rules: { min: 0 }
            },
            {
              name: "items",
              label: "Line Items",
              field_type: "array",
              required: false,
              options: {
                item_template: {
                  description: { type: "string" },
                  quantity: { type: "number" },
                  unit_price: { type: "number" }
                }
              }
            }
          ]
        }
      }
    }
    
    it "creates a new metadata template" do
      expect {
        post "/api/v1/metadata/templates", params: valid_params.to_json, headers: valid_headers
      }.to change(MetadataTemplate, :count).by(1)
      
      expect(response).to have_http_status(:created)
      
      json = JSON.parse(response.body)
      expect(json["template"]["name"]).to eq("Purchase Order")
      expect(json["template"]["fields"].count).to eq(4)
    end
    
    it "validates template uniqueness" do
      create(:metadata_template, name: "Purchase Order", organization: organization)
      
      post "/api/v1/metadata/templates", params: valid_params.to_json, headers: valid_headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]["name"]).to include("has already been taken")
    end
    
    it "validates field definitions" do
      invalid_params = valid_params.deep_merge(
        template: {
          fields_attributes: [
            { name: "", label: "Invalid Field", field_type: "string" }
          ]
        }
      )
      
      post "/api/v1/metadata/templates", params: invalid_params.to_json, headers: valid_headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end
  
  describe "PATCH /api/v1/metadata/templates/:id" do
    let(:template) { create(:metadata_template, organization: organization) }
    let(:update_params) {
      {
        template: {
          name: "Updated Template Name",
          fields_attributes: [
            {
              id: template.metadata_fields.first.id,
              label: "Updated Label",
              required: false
            },
            {
              name: "new_field",
              label: "New Field",
              field_type: "boolean",
              required: false
            }
          ]
        }
      }
    }
    
    it "updates the template and fields" do
      patch "/api/v1/metadata/templates/#{template.id}", 
            params: update_params.to_json, 
            headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      template.reload
      expect(template.name).to eq("Updated Template Name")
      expect(template.metadata_fields.count).to eq(template.metadata_fields.count)
      expect(template.metadata_fields.find_by(name: "new_field")).to be_present
    end
    
    it "prevents updating templates from other organizations" do
      other_template = create(:metadata_template)
      
      patch "/api/v1/metadata/templates/#{other_template.id}",
            params: update_params.to_json,
            headers: valid_headers
      
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe "DELETE /api/v1/metadata/templates/:id" do
    let!(:template) { create(:metadata_template, organization: organization) }
    
    it "deletes the template" do
      expect {
        delete "/api/v1/metadata/templates/#{template.id}", headers: valid_headers
      }.to change(MetadataTemplate, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
    end
    
    it "prevents deletion if template is in use" do
      document = create(:document, space: create(:space, organization: organization))
      document.metadata_template = template
      document.save!
      
      delete "/api/v1/metadata/templates/#{template.id}", headers: valid_headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("cannot be deleted")
    end
  end
  
  describe "POST /api/v1/documents/:id/metadata" do
    let(:space) { create(:space, organization: organization) }
    let(:document) { create(:document, space: space) }
    let(:template) { create(:metadata_template, 
      organization: organization,
      fields: [
        { name: "client", label: "Client", type: "string", required: true },
        { name: "amount", label: "Amount", type: "number", required: true }
      ]
    )}
    
    let(:metadata_params) {
      {
        metadata: {
          template_id: template.id,
          values: {
            client: "ABC Corporation",
            amount: 50000
          }
        }
      }
    }
    
    it "applies metadata to document" do
      post "/api/v1/documents/#{document.id}/metadata", 
           params: metadata_params.to_json,
           headers: valid_headers
      
      expect(response).to have_http_status(:created)
      
      json = JSON.parse(response.body)
      expect(json["metadata"]["client"]).to eq("ABC Corporation")
      expect(json["metadata"]["amount"]).to eq(50000)
      
      document.reload
      expect(document.metadata_template).to eq(template)
      expect(document.metadata.find_by(key: "client").value).to eq("ABC Corporation")
    end
    
    it "validates required fields" do
      invalid_params = metadata_params.deep_merge(
        metadata: { values: { client: "ABC Corporation" } } # Missing amount
      )
      
      post "/api/v1/documents/#{document.id}/metadata",
           params: invalid_params.to_json,
           headers: valid_headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]["amount"]).to include("is required")
    end
    
    it "validates field types" do
      invalid_params = metadata_params.deep_merge(
        metadata: { values: { amount: "not a number" } }
      )
      
      post "/api/v1/documents/#{document.id}/metadata",
           params: invalid_params.to_json,
           headers: valid_headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]["amount"]).to include("must be a number")
    end
  end
  
  describe "PATCH /api/v1/documents/:id/metadata" do
    let(:space) { create(:space, organization: organization) }
    let(:document) { create(:document, space: space) }
    
    before do
      document.metadata.create!([
        { key: "client", value: "Old Client" },
        { key: "status", value: "draft" }
      ])
    end
    
    it "updates existing metadata" do
      update_params = {
        metadata: {
          client: "New Client Name",
          status: "approved",
          new_field: "New Value"
        }
      }
      
      patch "/api/v1/documents/#{document.id}/metadata",
            params: update_params.to_json,
            headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      document.reload
      expect(document.metadata.find_by(key: "client").value).to eq("New Client Name")
      expect(document.metadata.find_by(key: "status").value).to eq("approved")
      expect(document.metadata.find_by(key: "new_field").value).to eq("New Value")
    end
    
    it "removes metadata fields when value is null" do
      update_params = {
        metadata: {
          client: nil,
          status: "final"
        }
      }
      
      expect {
        patch "/api/v1/documents/#{document.id}/metadata",
              params: update_params.to_json,
              headers: valid_headers
      }.to change { document.metadata.count }.by(-1)
      
      document.reload
      expect(document.metadata.find_by(key: "client")).to be_nil
      expect(document.metadata.find_by(key: "status").value).to eq("final")
    end
  end
  
  describe "GET /api/v1/metadata/fields/search" do
    before do
      # Créer des documents avec des métadonnées variées
      10.times do |i|
        doc = create(:document, space: create(:space, organization: organization))
        doc.metadata.create!([
          { key: "department", value: ["Sales", "Marketing", "IT", "HR"].sample },
          { key: "year", value: [2022, 2023, 2024].sample.to_s },
          { key: "status", value: ["active", "archived", "pending"].sample }
        ])
      end
    end
    
    it "returns unique metadata keys" do
      get "/api/v1/metadata/fields/search", headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["fields"]).to contain_exactly("department", "year", "status")
    end
    
    it "returns values for a specific key" do
      get "/api/v1/metadata/fields/search",
          params: { key: "department" },
          headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["values"]).to include("Sales", "Marketing", "IT", "HR")
      expect(json["counts"]).to be_present
    end
    
    it "autocompletes metadata values" do
      get "/api/v1/metadata/fields/search",
          params: { key: "department", q: "Mar" },
          headers: valid_headers
      
      json = JSON.parse(response.body)
      expect(json["values"]).to include("Marketing")
      expect(json["values"]).not_to include("Sales", "IT", "HR")
    end
  end
  
  describe "POST /api/v1/metadata/bulk" do
    let(:space) { create(:space, organization: organization) }
    let!(:documents) {
      3.times.map { create(:document, space: space) }
    }
    
    let(:bulk_params) {
      {
        document_ids: documents.map(&:id),
        metadata: {
          department: "Finance",
          fiscal_year: "2024",
          reviewed: true
        },
        mode: "merge" # or "replace"
      }
    }
    
    it "applies metadata to multiple documents" do
      post "/api/v1/metadata/bulk",
           params: bulk_params.to_json,
           headers: valid_headers
      
      expect(response).to have_http_status(:ok)
      
      json = JSON.parse(response.body)
      expect(json["updated_count"]).to eq(3)
      
      documents.each do |doc|
        doc.reload
        expect(doc.metadata.find_by(key: "department").value).to eq("Finance")
        expect(doc.metadata.find_by(key: "fiscal_year").value).to eq("2024")
      end
    end
    
    it "replaces all metadata when mode is replace" do
      # Ajouter des métadonnées existantes
      documents.first.metadata.create!(key: "old_field", value: "old_value")
      
      replace_params = bulk_params.merge(mode: "replace")
      
      post "/api/v1/metadata/bulk",
           params: replace_params.to_json,
           headers: valid_headers
      
      doc = documents.first.reload
      expect(doc.metadata.find_by(key: "old_field")).to be_nil
      expect(doc.metadata.count).to eq(3) # Seulement les nouvelles
    end
    
    it "handles partial failures" do
      # Rendre un document inaccessible
      documents.last.update!(space: create(:space)) # Autre organisation
      
      post "/api/v1/metadata/bulk",
           params: bulk_params.to_json,
           headers: valid_headers
      
      expect(response).to have_http_status(:multi_status)
      
      json = JSON.parse(response.body)
      expect(json["updated_count"]).to eq(2)
      expect(json["failed_count"]).to eq(1)
      expect(json["failures"]).to include(
        hash_including("document_id" => documents.last.id, "error" => "Forbidden")
      )
    end
  end
end