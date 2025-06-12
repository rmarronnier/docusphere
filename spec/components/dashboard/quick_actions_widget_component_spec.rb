require 'rails_helper'

RSpec.describe Dashboard::QuickActionsWidgetComponent, type: :component do
  let(:user) { create(:user) }
  let(:component) { described_class.new(user: user) }
  
  describe '#render' do
    before do
      render_inline(component)
    end
    
    it 'displays the widget title' do
      expect(page).to have_text('Actions rapides')
    end
    
    it 'shows base actions' do
      expect(page).to have_text('Nouveau document')
      expect(page).to have_text('Nouveau dossier')
      expect(page).to have_text('Recherche avancée')
      expect(page).to have_text('Mes bannettes')
    end
    
    it 'includes action descriptions' do
      expect(page).to have_text('Ajouter un fichier')
      expect(page).to have_text('Créer un dossier')
      expect(page).to have_text('Recherche détaillée')
      expect(page).to have_text('Documents favoris')
    end
    
    it 'shows help link' do
      expect(page).to have_text('Besoin d\'aide ?')
      expect(page).to have_link('Centre d\'aide')
    end
    
    context 'with different user profiles' do
      context 'when user is direction' do
        before do
          profile = create(:profile, user: user, profile_type: 'direction', is_active: true)
          allow(user).to receive(:active_profile).and_return(profile)
          render_inline(component)
        end
        
        it 'shows direction-specific actions' do
          expect(page).to have_text('Validations')
          expect(page).to have_text('Documents à valider')
          expect(page).to have_text('Rapports')
          expect(page).to have_text('Tableaux de bord')
        end
      end
      
      context 'when user is chef_projet' do
        before do
          profile = create(:profile, user: user, profile_type: 'chef_projet', is_active: true)
          allow(user).to receive(:active_profile).and_return(profile)
          render_inline(component)
        end
        
        it 'shows chef_projet-specific actions' do
          expect(page).to have_text('Mes projets')
          expect(page).to have_text('Projets en cours')
          expect(page).to have_text('Planning')
          expect(page).to have_text('Vue planning')
        end
      end
      
      context 'when user is commercial' do
        before do
          profile = create(:profile, user: user, profile_type: 'commercial', is_active: true)
          allow(user).to receive(:active_profile).and_return(profile)
          render_inline(component)
        end
        
        it 'shows commercial-specific actions' do
          expect(page).to have_text('Clients')
          expect(page).to have_text('Gestion clients')
          expect(page).to have_text('Propositions')
          expect(page).to have_text('Devis et contrats')
        end
      end
      
      context 'when user is juridique' do
        before do
          profile = create(:profile, user: user, profile_type: 'juridique', is_active: true)
          allow(user).to receive(:active_profile).and_return(profile)
          render_inline(component)
        end
        
        it 'shows juridique-specific actions' do
          expect(page).to have_text('Contrats')
          expect(page).to have_text('Suivi contrats')
          expect(page).to have_text('Conformité')
          expect(page).to have_text('Documents légaux')
        end
      end
    end
  end
  
  describe 'action links' do
    it 'has correct link structure' do
      render_inline(component)
      
      # Check that action links have the correct CSS classes
      expect(page).to have_css('a.group.relative.rounded-lg.p-4')
      
      # Check that icons are present
      expect(page).to have_css('svg.h-8.w-8')
      
      # Check arrow icons for navigation
      expect(page).to have_css('svg.h-5.w-5.opacity-50')
    end
  end
  
  describe 'helper methods' do
    subject { component }
    
    describe '#action_color_classes' do
      it 'returns correct color classes' do
        expect(subject.send(:action_color_classes, 'blue'))
          .to eq('bg-blue-50 text-blue-600 hover:bg-blue-100')
        expect(subject.send(:action_color_classes, 'green'))
          .to eq('bg-green-50 text-green-600 hover:bg-green-100')
        expect(subject.send(:action_color_classes, 'unknown'))
          .to eq('bg-gray-50 text-gray-600 hover:bg-gray-100')
      end
    end
  end
end