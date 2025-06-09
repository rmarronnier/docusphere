require 'rails_helper'

RSpec.describe Forms::FormErrorsComponent, type: :component do
  let(:model) { User.new }
  
  before do
    mock_component_helpers(described_class)
  end

  it "does not render when no errors" do
    rendered = render_inline(described_class.new(model: model))
    
    expect(rendered.to_html).to be_empty
  end

  it "renders when model has errors" do
    model.errors.add(:email, "can't be blank")
    model.errors.add(:name, "is too short")
    
    rendered = render_inline(described_class.new(model: model))
    
    expect(rendered).to have_css('.rounded-md.bg-red-50')
    expect(rendered).to have_text("2 erreurs empêchent l'enregistrement")
    expect(rendered).to have_text("Email can't be blank")
    expect(rendered).to have_text("Name is too short")
  end

  it "uses singular form for one error" do
    model.errors.add(:email, "is invalid")
    
    rendered = render_inline(described_class.new(model: model))
    
    expect(rendered).to have_text("1 erreur empêche l'enregistrement")
  end

  it "displays error icon" do
    model.errors.add(:email, "is invalid")
    
    rendered = render_inline(described_class.new(model: model))
    
    expect(rendered).to have_css('svg')
    expect(rendered).to have_css('.text-red-400')
  end

  it "renders errors in a list" do
    model.errors.add(:email, "is invalid")
    model.errors.add(:password, "is too short")
    
    rendered = render_inline(described_class.new(model: model))
    
    expect(rendered).to have_css('ul.list-disc')
    expect(rendered).to have_css('li', count: 2)
  end
end