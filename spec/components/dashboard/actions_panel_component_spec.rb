require 'rails_helper'

RSpec.describe Dashboard::ActionsPanelComponent, type: :component do
  let(:user) { create(:user) }
  let(:actions) do
    [
      {
        type: 'validation',
        title: 'Validations en attente',
        count: 3,
        urgency: 'high',
        link: '/validations/pending',
        icon: 'check-circle'
      },
      {
        type: 'task',
        title: 'Tâches en retard',
        count: 2,
        urgency: 'medium',
        link: '/tasks/overdue',
        icon: 'clock'
      }
    ]
  end
  
  context 'with actions' do
    it 'renders all actions' do
      render_inline(described_class.new(actions: actions, user: user))
      
      expect(page).to have_text('Actions prioritaires')
      expect(page).to have_text('Validations en attente')
      expect(page).to have_text('3')
      expect(page).to have_text('Tâches en retard')
      expect(page).to have_text('2')
    end
    
    it 'applies urgency-based styling' do
      render_inline(described_class.new(actions: actions, user: user))
      
      expect(page).to have_css('.bg-orange-100') # high urgency
      expect(page).to have_css('.bg-yellow-100') # medium urgency
    end
    
    it 'renders action links' do
      render_inline(described_class.new(actions: actions, user: user))
      
      expect(page).to have_link(href: '/validations/pending')
      expect(page).to have_link(href: '/tasks/overdue')
    end
  end
  
  context 'without actions' do
    it 'shows empty state' do
      render_inline(described_class.new(actions: [], user: user))
      
      expect(page).to have_text('Actions prioritaires')
      expect(page).to have_text('Aucune action en attente')
    end
  end
  
  context 'when collapsed' do
    it 'hides content but shows count badge' do
      render_inline(described_class.new(actions: actions, user: user, collapsed: true))
      
      expect(page).to have_css('.collapsed')
      expect(page).to have_css('.hidden') # elements are hidden
      expect(page).to have_text('5') # total count badge (3 + 2)
    end
  end
  
  describe 'grouping' do
    let(:mixed_actions) do
      [
        { type: 'validation', title: 'Validation 1', count: 1, urgency: 'high', link: '/v1', icon: 'check' },
        { type: 'task', title: 'Task 1', count: 2, urgency: 'medium', link: '/t1', icon: 'clock' },
        { type: 'validation', title: 'Validation 2', count: 3, urgency: 'high', link: '/v2', icon: 'check' }
      ]
    end
    
    it 'groups actions by type' do
      render_inline(described_class.new(actions: mixed_actions, user: user))
      
      # Should group validations together
      validation_blocks = page.all('a[href^="/v"]')
      expect(validation_blocks.size).to eq(2)
    end
  end
  
  describe 'toggle button' do
    it 'renders toggle button' do
      render_inline(described_class.new(actions: actions, user: user))
      
      expect(page).to have_css('[data-action="click->actions-panel#toggle"]')
    end
    
    it 'rotates icon when collapsed' do
      render_inline(described_class.new(actions: actions, user: user, collapsed: true))
      
      expect(page).to have_css('svg.rotate-180')
    end
  end
  
  describe 'action icons' do
    let(:actions_with_icons) do
      [
        { type: 'notification', title: 'Notifications', count: 5, urgency: 'low', link: '/notifs', icon: 'bell' }
      ]
    end
    
    it 'renders action icons' do
      render_inline(described_class.new(actions: actions_with_icons, user: user))
      
      expect(page).to have_css('svg', minimum: 2) # At least icon + toggle button
    end
  end
  
  describe 'action subtitles' do
    let(:actions_with_subtitles) do
      [
        { 
          type: 'validation',
          title: 'Documents urgents',
          subtitle: 'À traiter avant demain',
          count: 2,
          urgency: 'critical',
          link: '/urgent',
          icon: 'exclamation'
        }
      ]
    end
    
    it 'renders subtitles when present' do
      render_inline(described_class.new(actions: actions_with_subtitles, user: user))
      
      expect(page).to have_text('À traiter avant demain')
      expect(page).to have_css('.text-xs.text-gray-600')
    end
  end
end