require 'rails_helper'

RSpec.describe Ui::UserAvatarComponent, type: :component do
  let(:user) { create(:user, first_name: 'John', last_name: 'Doe', email: 'john@example.com') }

  it "renders user initials" do
    rendered = render_inline(described_class.new(user: user))
    
    expect(rendered).to have_css('.rounded-full')
    expect(rendered).to have_text('JD')
  end

  it "renders with different sizes" do
    rendered_sm = render_inline(described_class.new(user: user, size: 'sm'))
    rendered_lg = render_inline(described_class.new(user: user, size: 'lg'))
    
    expect(rendered_sm).to have_css('.h-8.w-8')
    expect(rendered_lg).to have_css('.h-12.w-12')
  end

  it "shows tooltip when enabled" do
    rendered = render_inline(described_class.new(user: user, show_tooltip: true))
    
    expect(rendered).to have_css('[title="John Doe"]')
  end

  it "handles missing first name" do
    user.first_name = nil
    rendered = render_inline(described_class.new(user: user))
    
    expect(rendered).to have_text('D')
  end

  it "handles missing last name" do
    user.last_name = nil
    rendered = render_inline(described_class.new(user: user))
    
    expect(rendered).to have_text('J')
  end

  it "uses email initial when no names" do
    user.first_name = nil
    user.last_name = nil
    rendered = render_inline(described_class.new(user: user))
    
    expect(rendered).to have_text('J')
  end

  it "generates consistent background colors" do
    rendered1 = render_inline(described_class.new(user: user))
    rendered2 = render_inline(described_class.new(user: user))
    
    # Should have the same background color class
    expect(rendered1.css('.rounded-full').first['class']).to eq(rendered2.css('.rounded-full').first['class'])
  end
end