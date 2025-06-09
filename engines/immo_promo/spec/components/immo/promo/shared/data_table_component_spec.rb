require 'rails_helper'

RSpec.describe Immo::Promo::Shared::DataTableComponent, type: :component do
  let(:items) do
    [
      { id: 1, name: 'Projet Alpha', status: 'in_progress', progress: 75 },
      { id: 2, name: 'Projet Beta', status: 'completed', progress: 100 }
    ]
  end

  let(:columns) do
    [
      { key: :name, label: 'Nom' },
      { key: :status, label: 'Statut', type: :status },
      { key: :progress, label: 'Progression', type: :progress }
    ]
  end

  it "renders table with items and columns" do
    rendered = render_inline(described_class.new(items: items, columns: columns))
    
    expect(rendered).to have_css('table')
    expect(rendered).to have_text('Projet Alpha')
    expect(rendered).to have_text('Projet Beta')
  end

  it "renders empty state with French message" do
    rendered = render_inline(described_class.new(
      items: [], 
      columns: columns
    ))
    
    expect(rendered).to have_text('Aucune donnée disponible')
  end

  it "applies striped and hoverable by default" do
    rendered = render_inline(described_class.new(items: items, columns: columns))
    
    expect(rendered).to have_css('.table-striped')
    expect(rendered).to have_css('.hover\\:bg-gray-50')
  end

  it "renders ImmoPromo-specific status badges" do
    rendered = render_inline(described_class.new(items: items, columns: columns))
    
    # Should use ImmoPromo's StatusBadgeComponent with French labels
    expect(rendered).to have_text('En cours')
    expect(rendered).to have_text('Terminé')
  end

  it "renders ImmoPromo progress indicators" do
    rendered = render_inline(described_class.new(items: items, columns: columns))
    
    # Should render progress bars
    expect(rendered).to have_css('[style*="width: 75%"]')
    expect(rendered).to have_css('[style*="width: 100%"]')
  end

  it "passes actions parameter" do
    actions = ['edit', 'delete']
    rendered = render_inline(described_class.new(
      items: items, 
      columns: columns,
      actions: actions
    ))
    
    expect(rendered).to have_css('table')
  end
end