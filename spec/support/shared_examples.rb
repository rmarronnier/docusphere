# Shared examples for common test patterns

# Load all shared examples from subdirectory
Dir[Rails.root.join('spec/support/shared_examples/*.rb')].sort.each { |f| require f }

RSpec.shared_examples "requires authentication" do
  it "redirects to login when not authenticated" do
    sign_out if respond_to?(:sign_out)
    perform_action
    
    if request.present?
      expect(response).to redirect_to(new_user_session_path)
    else
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end

RSpec.shared_examples "requires admin role" do
  let(:regular_user) { create(:user) }
  
  it "denies access for non-admin users" do
    sign_in regular_user
    perform_action
    
    if request.present?
      expect(response).to have_http_status(:forbidden)
    else
      expect(page).to have_content("Accès refusé")
    end
  end
end

RSpec.shared_examples "authorizable resource" do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user, organization: owner.organization) }
  let(:external_user) { create(:user) }
  
  it "allows access for resource owner" do
    sign_in owner
    resource = create_resource(user: owner)
    perform_action(resource)
    
    expect_success
  end
  
  it "allows access for users in same organization" do
    sign_in other_user
    resource = create_resource(user: owner)
    perform_action(resource)
    
    expect_success
  end
  
  it "denies access for external users" do
    sign_in external_user
    resource = create_resource(user: owner)
    perform_action(resource)
    
    expect_forbidden
  end
end

RSpec.shared_examples "paginatable index" do
  before do
    create_list(resource_name, 30)
  end
  
  it "paginates results" do
    visit index_path
    
    expect(page).to have_css('.pagination')
    expect(page).to have_css(item_selector, count: per_page)
  end
  
  it "navigates between pages" do
    visit index_path
    
    click_link "2"
    expect(page).to have_css('.pagination .active', text: "2")
  end
end

RSpec.shared_examples "searchable resource" do
  let(:searchable) { create(resource_name, searchable_attributes) }
  let(:non_matching) { create(resource_name, non_matching_attributes) }
  
  it "finds resources matching search query" do
    searchable
    non_matching
    
    visit index_path
    fill_in "search", with: search_query
    click_button "Rechercher"
    
    expect(page).to have_content(searchable.title)
    expect(page).not_to have_content(non_matching.title)
  end
  
  it "shows message when no results found" do
    visit index_path
    fill_in "search", with: "nonexistentquery123"
    click_button "Rechercher"
    
    expect(page).to have_content("Aucun résultat")
  end
end

RSpec.shared_examples "soft deletable" do
  let(:resource) { create(resource_name) }
  
  it "soft deletes the resource" do
    expect {
      resource.destroy
    }.not_to change { resource.class.unscoped.count }
    
    expect(resource.reload.deleted_at).to be_present
  end
  
  it "excludes soft deleted records from default scope" do
    resource.destroy
    
    expect(resource.class.all).not_to include(resource)
    expect(resource.class.with_deleted).to include(resource)
  end
  
  it "can be restored" do
    resource.destroy
    resource.restore
    
    expect(resource.reload.deleted_at).to be_nil
    expect(resource.class.all).to include(resource)
  end
end

RSpec.shared_examples "taggable resource" do
  let(:resource) { create(resource_name) }
  let(:tag1) { create(:tag, name: "Important") }
  let(:tag2) { create(:tag, name: "Urgent") }
  
  it "can be tagged" do
    resource.tags << [tag1, tag2]
    
    expect(resource.tags).to include(tag1, tag2)
    expect(resource.tag_list).to eq("Important, Urgent")
  end
  
  it "can find resources by tag" do
    resource.tags << tag1
    other_resource = create(resource_name)
    other_resource.tags << tag2
    
    expect(resource.class.tagged_with("Important")).to include(resource)
    expect(resource.class.tagged_with("Important")).not_to include(other_resource)
  end
end

RSpec.shared_examples "auditable resource" do
  let(:user) { create(:user) }
  let(:resource) { create(resource_name, auditable_attributes) }
  
  around do |example|
    Audited.auditing_enabled = true
    example.run
    Audited.auditing_enabled = false
  end
  
  it "tracks creation" do
    expect {
      resource
    }.to change { Audited::Audit.count }.by(1)
    
    audit = resource.audits.last
    expect(audit.action).to eq("create")
    expect(audit.audited_changes).to include(auditable_attributes.stringify_keys)
  end
  
  it "tracks updates" do
    resource.update!(auditable_update_attributes)
    
    audit = resource.audits.last
    expect(audit.action).to eq("update")
    expect(audit.audited_changes).to include(auditable_update_attributes.stringify_keys)
  end
  
  it "tracks user who made changes" do
    Audited.store[:current_user] = user
    resource.update!(auditable_update_attributes)
    
    expect(resource.audits.last.user).to eq(user)
  end
end

RSpec.shared_examples "has metadata" do
  let(:resource) { create(resource_name) }
  
  it "stores metadata key-value pairs" do
    resource.metadata.create!(key: "client", value: "ABC Corp")
    resource.metadata.create!(key: "priority", value: "high")
    
    expect(resource.metadata.count).to eq(2)
    expect(resource.metadata_value("client")).to eq("ABC Corp")
    expect(resource.metadata_value("priority")).to eq("high")
  end
  
  it "updates existing metadata" do
    metadata = resource.metadata.create!(key: "status", value: "draft")
    
    resource.update_metadata("status", "published")
    
    expect(resource.metadata_value("status")).to eq("published")
    expect(resource.metadata.count).to eq(1)
  end
  
  it "can search by metadata" do
    resource.metadata.create!(key: "department", value: "Sales")
    other = create(resource_name)
    other.metadata.create!(key: "department", value: "Marketing")
    
    results = resource.class.with_metadata("department", "Sales")
    
    expect(results).to include(resource)
    expect(results).not_to include(other)
  end
end

RSpec.shared_examples "exportable resource" do
  let(:resources) { create_list(resource_name, 3) }
  
  it "exports to CSV" do
    csv_data = described_class.to_csv(resources)
    
    expect(csv_data).to include(csv_headers.join(","))
    resources.each do |resource|
      expect(csv_data).to include(resource.title)
    end
  end
  
  it "exports to JSON" do
    json_data = described_class.to_json_export(resources)
    parsed = JSON.parse(json_data)
    
    expect(parsed["data"].count).to eq(3)
    expect(parsed["data"].first.keys).to include(*json_attributes)
  end
  
  it "exports to PDF" do
    pdf_data = described_class.to_pdf(resources)
    
    expect(pdf_data).to be_present
    expect(pdf_data[0..3]).to eq("%PDF") # PDF magic number
  end
end

RSpec.shared_examples "filterable resource" do
  describe "filtering" do
    let!(:active_resource) { create(resource_name, status: 'active') }
    let!(:inactive_resource) { create(resource_name, status: 'inactive') }
    let!(:recent_resource) { create(resource_name, created_at: 1.day.ago) }
    let!(:old_resource) { create(resource_name, created_at: 1.year.ago) }
    
    it "filters by status" do
      visit index_path
      select "Active", from: "status"
      click_button "Filtrer"
      
      expect(page).to have_content(active_resource.title)
      expect(page).not_to have_content(inactive_resource.title)
    end
    
    it "filters by date range" do
      visit index_path
      fill_in "from_date", with: 1.week.ago
      fill_in "to_date", with: Date.today
      click_button "Filtrer"
      
      expect(page).to have_content(recent_resource.title)
      expect(page).not_to have_content(old_resource.title)
    end
    
    it "combines multiple filters" do
      active_recent = create(resource_name, status: 'active', created_at: 1.day.ago)
      
      visit index_path
      select "Active", from: "status"
      fill_in "from_date", with: 1.week.ago
      click_button "Filtrer"
      
      expect(page).to have_content(active_recent.title)
      expect(page).not_to have_content(inactive_resource.title)
      expect(page).not_to have_content(old_resource.title)
    end
  end
end

RSpec.shared_examples "versionable resource" do
  let(:resource) { create(resource_name) }
  let(:user) { create(:user) }
  
  it "creates versions on update" do
    original_title = resource.title
    
    resource.update!(title: "New Title", updated_by: user)
    
    expect(resource.versions.count).to eq(2) # Create + Update
    expect(resource.versions.last.title).to eq("New Title")
    expect(resource.versions.first.title).to eq(original_title)
  end
  
  it "can revert to previous version" do
    resource.update!(title: "Version 2")
    resource.update!(title: "Version 3")
    
    resource.revert_to_version!(1)
    
    expect(resource.reload.title).to eq(resource.versions.first.title)
  end
  
  it "tracks who made changes" do
    resource.update!(title: "Updated", updated_by: user)
    
    expect(resource.versions.last.updated_by).to eq(user)
  end
end

RSpec.shared_examples "has workflow" do
  let(:resource) { create(resource_name) }
  let(:workflow) { create(:workflow) }
  
  before do
    resource.assign_workflow(workflow)
  end
  
  it "starts in initial state" do
    expect(resource.workflow_state).to eq("draft")
  end
  
  it "transitions between states" do
    expect(resource.can_submit?).to be true
    
    resource.submit!
    
    expect(resource.workflow_state).to eq("review")
    expect(resource.can_approve?).to be true
    expect(resource.can_reject?).to be true
  end
  
  it "records transition history" do
    resource.submit!(by: user, comment: "Ready for review")
    
    transition = resource.workflow_transitions.last
    expect(transition.from_state).to eq("draft")
    expect(transition.to_state).to eq("review")
    expect(transition.user).to eq(user)
    expect(transition.comment).to eq("Ready for review")
  end
  
  it "prevents invalid transitions" do
    expect {
      resource.approve! # Can't approve from draft
    }.to raise_error(WorkflowError)
  end
end

# Helper method to use in specs
def it_behaves_like_authenticated_resource
  it_behaves_like "requires authentication" do
    let(:perform_action) { visit path }
  end
end

def it_behaves_like_admin_resource
  it_behaves_like "requires admin role" do
    let(:perform_action) { visit path }
  end
end