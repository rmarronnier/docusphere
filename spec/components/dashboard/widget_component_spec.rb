require 'rails_helper'

RSpec.describe Dashboard::WidgetComponent, type: :component do
  let(:widget_data) do
    {
      id: 1,
      type: 'test_widget',
      title: 'Test Widget',
      actions: [
        { icon: 'refresh', type: 'refresh' },
        { icon: 'cog', type: 'settings' }
      ]
    }
  end
  
  context 'with normal state' do
    it 'renders widget with title and actions' do
      render_inline(described_class.new(widget_data: widget_data)) do
        "Widget content"
      end
      
      expect(page).to have_text('Test Widget')
      expect(page).to have_text('Widget content')
      expect(page).to have_css('[data-widget-id="1"]')
      expect(page).to have_css('button', count: 2)
    end
    
    it 'renders without header when no title or actions' do
      widget_data_without_header = { id: 2, type: 'simple' }
      
      render_inline(described_class.new(widget_data: widget_data_without_header)) do
        "Simple content"
      end
      
      expect(page).to have_text('Simple content')
      expect(page).not_to have_css('.widget-header')
    end
  end
  
  context 'with loading state' do
    it 'renders loading skeleton' do
      render_inline(described_class.new(widget_data: widget_data, loading: true))
      
      expect(page).to have_css('.animate-pulse')
      expect(page).not_to have_text('Test Widget')
      expect(page).to have_css('.bg-gray-200', count: 3)
    end
  end
  
  context 'with error state' do
    it 'renders error message' do
      render_inline(described_class.new(
        widget_data: widget_data,
        error: "Erreur de chargement"
      ))
      
      expect(page).to have_text('Erreur de chargement')
      expect(page).to have_css('.border-red-300')
      expect(page).to have_css('.text-red-400')
    end
  end
  
  context 'with different sizes' do
    it 'applies correct grid classes' do
      render_inline(described_class.new(
        widget_data: widget_data,
        size: { width: 2, height: 2 }
      ))
      
      expect(page).to have_css('.col-span-2.row-span-2')
    end
    
    it 'uses default size when not specified' do
      render_inline(described_class.new(widget_data: widget_data))
      
      expect(page).not_to have_css('.col-span-2')
      expect(page).not_to have_css('.row-span-2')
    end
  end
  
  context 'with refreshable widget' do
    it 'shows refresh button' do
      widget_data[:refreshable] = true
      
      render_inline(described_class.new(widget_data: widget_data))
      
      expect(page).to have_css('[data-action="refresh-widget"]')
      expect(page).to have_css('[data-widget-id="1"]', count: 2) # once on main div, once on refresh button
    end
  end
  
  context 'with footer' do
    it 'renders footer content' do
      widget_data[:footer] = '<a href="/more">View More</a>'.html_safe
      
      render_inline(described_class.new(widget_data: widget_data))
      
      expect(page).to have_link('View More', href: '/more')
      expect(page).to have_css('.border-t.border-gray-200')
    end
  end
  
  describe 'CSS classes' do
    it 'applies base widget classes' do
      render_inline(described_class.new(widget_data: widget_data))
      
      expect(page).to have_css('.dashboard-widget')
      expect(page).to have_css('.bg-white')
      expect(page).to have_css('.rounded-lg')
      expect(page).to have_css('.shadow')
      expect(page).to have_css('.p-4')
      expect(page).to have_css('.relative')
    end
    
    it 'applies loading class when loading' do
      render_inline(described_class.new(widget_data: widget_data, loading: true))
      
      expect(page).to have_css('.animate-pulse')
    end
    
    it 'applies error border when error' do
      render_inline(described_class.new(widget_data: widget_data, error: "Error"))
      
      expect(page).to have_css('.border-red-300')
    end
  end
end