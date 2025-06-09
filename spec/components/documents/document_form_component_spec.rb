require 'rails_helper'

RSpec.describe Documents::DocumentFormComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { create(:space, organization: user.organization) }
  let(:document) { build(:document, space: space) }
  let(:spaces) { [space] }
  
  before do
    mock_component_helpers(described_class, user: user, additional_helpers: {
      ged_document_path: ->(doc) { "/ged/documents/#{doc.id}" },
      ged_upload_document_path: '/ged/documents/upload',
      policy_scope: ->(scope) { scope }
    })
  end
  
  it "renders form component" do
    rendered = render_inline(described_class.new(
      document: document
    ))
    
    expect(rendered).to have_css('form')
  end
  
  it "renders with edit mode for existing document" do
    existing_document = create(:document, space: space)
    
    rendered = render_inline(described_class.new(
      document: existing_document
    ))
    
    expect(rendered).to have_css('form')
  end
end