require 'rails_helper'

RSpec.describe Dashboard::StatisticsWidget, type: :component do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:widget_data) do
    {
      id: 5,
      type: 'statistics',
      title: 'Statistiques',
      config: {},
      data: { stats: statistics }
    }
  end
  
  context 'with statistics' do
    let(:statistics) do
      [
        {
          id: 1,
          label: 'Documents',
          value: 156,
          trend: { direction: 'up', percentage: 12 },
          icon: 'document',
          color: 'blue'
        },
        {
          id: 2,
          label: 'Projets actifs', 
          value: 8,
          trend: { direction: 'down', percentage: 5 },
          icon: 'folder',
          color: 'green'
        },
        {
          id: 3,
          label: 'Validations en attente',
          value: 24,
          trend: { direction: 'neutral', percentage: 0 },
          icon: 'clock',
          color: 'orange'
        },
        {
          id: 4,
          label: 'Taux de conformité',
          value: '94%',
          trend: { direction: 'up', percentage: 3 },
          icon: 'check-circle',
          color: 'purple'
        }
      ]
    end
    
    it 'renders statistics cards' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Statistiques')
      expect(page).to have_text('Documents')
      expect(page).to have_text('Projets actifs')
      expect(page).to have_text('Validations en attente')
      expect(page).to have_text('Taux de conformité')
    end
    
    it 'shows statistic values' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('156')
      expect(page).to have_text('8')
      expect(page).to have_text('24')
      expect(page).to have_text('94%')
    end
    
    it 'shows trends with percentages' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('+12%')
      expect(page).to have_text('-5%')
      expect(page).to have_text('+3%')
    end
    
    it 'shows trend indicators' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-trend="up"]', count: 2)
      expect(page).to have_css('[data-trend="down"]', count: 1)
      expect(page).to have_css('[data-trend="neutral"]', count: 1)
    end
    
    it 'applies color themes' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-color="blue"]')
      expect(page).to have_css('[data-color="green"]')
      expect(page).to have_css('[data-color="orange"]')
      expect(page).to have_css('[data-color="purple"]')
    end
    
    it 'shows icons for each statistic' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-icon="document"]')
      expect(page).to have_css('[data-icon="folder"]')
      expect(page).to have_css('[data-icon="clock"]')
      expect(page).to have_css('[data-icon="check-circle"]')
    end
  end
  
  context 'without statistics' do
    let(:statistics) { [] }
    
    it 'shows empty state' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Aucune statistique disponible')
      expect(page).to have_css('.empty-state')
    end
  end
  
  context 'with loading state' do
    let(:statistics) { [] }
    
    it 'shows loading skeleton' do
      render_inline(described_class.new(
        widget_data: widget_data.merge(loading: true), 
        user: user
      ))
      
      expect(page).to have_css('.loading-skeleton')
    end
  end
  
  context 'with custom layout' do
    let(:statistics) do 
      Array.new(6) do |i|
        {
          id: i + 1,
          label: "Métrique #{i + 1}",
          value: rand(100..999),
          trend: { direction: 'up', percentage: rand(1..20) },
          icon: 'chart',
          color: 'gray'
        }
      end
    end
    
    it 'displays statistics in grid layout' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.stat-card', count: 6)
      expect(page).to have_css('.grid')
    end
  end
  
  context 'with custom columns' do
    let(:statistics) do 
      Array.new(4) do |i|
        {
          id: i + 1,
          label: "Métrique #{i + 1}",
          value: 100,
          icon: 'chart',
          color: 'gray'
        }
      end
    end
    
    it 'applies custom column configuration' do
      widget_data[:config][:columns] = 2
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.sm\\:grid-cols-2')
    end
  end
  
  context 'with formatted values' do
    let(:statistics) do
      [
        { id: 1, label: 'Large number', value: 1234567, icon: 'chart', color: 'blue' },
        { id: 2, label: 'Decimal', value: 45.67, icon: 'chart', color: 'green' },
        { id: 3, label: 'Percentage', value: '89.5%', icon: 'chart', color: 'purple' },
        { id: 4, label: 'Text value', value: 'Active', icon: 'chart', color: 'orange' }
      ]
    end
    
    it 'formats different value types correctly' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('1,234,567')
      expect(page).to have_text('45.67')
      expect(page).to have_text('89.5%')
      expect(page).to have_text('Active')
    end
  end
end