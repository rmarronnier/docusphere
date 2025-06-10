require 'rails_helper'

RSpec.describe Dashboard::PendingTasksWidget, type: :component do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  let(:widget_data) do
    {
      id: 2,
      type: 'pending_tasks',
      title: 'Tâches en attente',
      config: {},
      data: { tasks: tasks }
    }
  end
  
  context 'with pending tasks' do
    let(:tasks) do
      [
        {
          id: 1,
          title: 'Valider le document technique',
          type: 'validation',
          urgency: 'high',
          due_date: 1.day.from_now,
          assignee: 'Jean Dupont',
          link: '/validations/1'
        },
        {
          id: 2,
          title: 'Réviser le contrat fournisseur', 
          type: 'review',
          urgency: 'medium',
          due_date: 3.days.from_now,
          assignee: nil,
          link: '/documents/2/edit'
        },
        {
          id: 3,
          title: 'Approuver le budget projet',
          type: 'approval',
          urgency: 'low',
          due_date: 1.week.from_now,
          assignee: 'Marie Martin',
          link: '/projects/1/budget'
        }
      ]
    end
    
    it 'renders task list' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Tâches en attente')
      expect(page).to have_text('Valider le document technique')
      expect(page).to have_text('Réviser le contrat fournisseur')
      expect(page).to have_text('Approuver le budget projet')
    end
    
    it 'shows task urgency indicators' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-urgency="high"]')
      expect(page).to have_css('[data-urgency="medium"]')
      expect(page).to have_css('[data-urgency="low"]')
    end
    
    it 'shows due dates' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Demain')  # 1.day.from_now is "Demain"
      expect(page).to have_text('Dans 3 jours')
      expect(page).to have_text('Dans 7 jours')
    end
    
    it 'shows assignee when present' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Jean Dupont')
      expect(page).to have_text('Marie Martin')
    end
    
    it 'includes links to tasks' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_link('Valider le document technique', href: '/validations/1')
      expect(page).to have_link('Réviser le contrat fournisseur', href: '/documents/2/edit')
      expect(page).to have_link('Approuver le budget projet', href: '/projects/1/budget')
    end
    
    it 'shows task type icons' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-task-type="validation"]')
      expect(page).to have_css('[data-task-type="review"]')
      expect(page).to have_css('[data-task-type="approval"]')
    end
  end
  
  context 'without tasks' do
    let(:tasks) { [] }
    
    it 'shows empty state' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Aucune tâche en attente')
      expect(page).to have_css('.empty-state')
    end
    
    it 'shows success message' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_text('Toutes vos tâches sont terminées')
    end
  end
  
  context 'with loading state' do
    let(:tasks) { [] }
    
    it 'shows loading skeleton' do
      render_inline(described_class.new(
        widget_data: widget_data.merge(loading: true), 
        user: user
      ))
      
      expect(page).to have_css('.loading-skeleton')
    end
  end
  
  context 'with custom limit' do
    let(:tasks) do 
      Array.new(10) do |i|
        {
          id: i + 1,
          title: "Tâche #{i + 1}",
          type: 'task',
          urgency: 'medium',
          due_date: 1.day.from_now,
          link: "/tasks/#{i + 1}"
        }
      end
    end
    
    it 'respects the configured limit' do
      widget_data[:config][:limit] = 3
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('.task-item', count: 3)
    end
  end
  
  context 'with view all link' do
    let(:tasks) { Array.new(6) { |i| { id: i + 1, title: "Tâche #{i + 1}", type: 'task', urgency: 'medium', due_date: 1.day.from_now, link: "/tasks/#{i + 1}" } } }
    
    it 'shows view all link when there are more tasks' do
      widget_data[:config][:limit] = 5
      widget_data[:data][:total_count] = 10
      
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_link('Voir toutes les tâches', href: '/tasks')
    end
  end
  
  context 'with overdue tasks' do
    let(:tasks) do
      [
        {
          id: 1,
          title: 'Tâche en retard',
          type: 'validation',
          urgency: 'high',
          due_date: 2.days.ago,
          link: '/validations/1'
        }
      ]
    end
    
    it 'highlights overdue tasks' do
      render_inline(described_class.new(widget_data: widget_data, user: user))
      
      expect(page).to have_css('[data-overdue="true"]')
      expect(page).to have_text('En retard de 2 jours')
    end
  end
end