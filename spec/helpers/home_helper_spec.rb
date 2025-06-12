require 'rails_helper'

RSpec.describe HomeHelper, type: :helper do
  describe '#greeting_message_for_time' do
    it 'returns morning greeting for morning hours' do
      allow(Time).to receive(:current).and_return(Time.parse('09:00'))
      expect(helper.greeting_message_for_time).to eq("Bonne matinée ! Voici votre tableau de bord pour aujourd'hui.")
    end
    
    it 'returns afternoon greeting for afternoon hours' do
      allow(Time).to receive(:current).and_return(Time.parse('15:00'))
      expect(helper.greeting_message_for_time).to eq("Bon après-midi ! Voici l'état de vos documents et activités.")
    end
    
    it 'returns evening greeting for evening hours' do
      allow(Time).to receive(:current).and_return(Time.parse('20:00'))
      expect(helper.greeting_message_for_time).to eq("Bonsoir ! Retrouvez vos documents et tâches en cours.")
    end
  end
  
  describe '#widget_icon' do
    it 'returns correct icon names' do
      expect(helper.widget_icon(:pending_documents)).to eq('clipboard-list')
      expect(helper.widget_icon(:recent_activity)).to eq('clock')
      expect(helper.widget_icon(:quick_actions)).to eq('lightning-bolt')
      expect(helper.widget_icon(:statistics)).to eq('chart-bar')
      expect(helper.widget_icon(:validation_queue)).to eq('check-circle')
      expect(helper.widget_icon(:project_documents)).to eq('folder-open')
      expect(helper.widget_icon(:client_documents)).to eq('users')
      expect(helper.widget_icon(:unknown)).to eq('cube')
    end
  end
  
  describe '#widget_color_class' do
    it 'returns correct color classes' do
      expect(helper.widget_color_class(:pending_documents)).to eq('text-orange-600 bg-orange-100')
      expect(helper.widget_color_class(:recent_activity)).to eq('text-blue-600 bg-blue-100')
      expect(helper.widget_color_class(:quick_actions)).to eq('text-purple-600 bg-purple-100')
      expect(helper.widget_color_class(:statistics)).to eq('text-green-600 bg-green-100')
      expect(helper.widget_color_class(:validation_queue)).to eq('text-red-600 bg-red-100')
      expect(helper.widget_color_class(:project_documents)).to eq('text-indigo-600 bg-indigo-100')
      expect(helper.widget_color_class(:client_documents)).to eq('text-yellow-600 bg-yellow-100')
      expect(helper.widget_color_class(:unknown)).to eq('text-gray-600 bg-gray-100')
    end
  end
end