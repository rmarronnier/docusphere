# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ged::FolderCardComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:folder) { create(:folder, space: space, name: "Test Folder", description: "Test description") }
  let(:component) { described_class.new(folder: folder, current_user: user) }

  before do
    helpers_mock = double(
      ged_folder_path: "/ged/folders/#{folder.id}",
      ged_folder_permissions_path: "/ged/folders/#{folder.id}/permissions",
      heroicon: "<svg></svg>".html_safe,
      pluralize: "1 document",
      time_ago_in_words: "2 hours",
      l: "13/06/2025"
    )
    allow(component).to receive(:helpers).and_return(helpers_mock)
  end

  describe 'initialization' do
    it 'accepts required parameters' do
      expect(component.folder).to eq(folder)
      expect(component.current_user).to eq(user)
    end

    it 'accepts optional parameters' do
      component = described_class.new(
        folder: folder, 
        current_user: user, 
        show_actions: false, 
        draggable: false
      )
      
      expect(component.show_actions).to be(false)
      expect(component.draggable).to be(false)
    end

    it 'sets default values for optional parameters' do
      expect(component.show_actions).to be(true)
      expect(component.draggable).to be(true)
    end
  end

  describe 'rendering' do
    let(:rendered_component) { render_inline(component) }

    it 'renders the folder card' do
      expect(rendered_component.to_html).to include('class')
      expect(rendered_component.to_html).to include('group')
    end

    it 'displays folder name' do
      expect(rendered_component.text).to include(folder.name)
    end

    it 'displays folder description when present' do
      expect(rendered_component.text).to include(folder.description)
    end

    it 'includes drag and drop attributes when draggable' do
      expect(rendered_component.to_html).to include('draggable="true"')
      expect(rendered_component.to_html).to include('folder_id')
    end

    it 'excludes drag and drop attributes when not draggable' do
      component = described_class.new(folder: folder, current_user: user, draggable: false)
      drag_attributes = component.send(:drag_data_attributes)
      
      expect(drag_attributes).to be_empty
    end

    context 'when folder has no description' do
      let(:folder) { create(:folder, space: space, name: "Test Folder", description: nil) }

      it 'does not show description section' do
        expect(rendered_component.text).not_to include('Test description')
      end
    end
  end

  describe 'document count display' do
    context 'when folder has no documents' do
      it 'displays "Aucun document"' do
        expect(component.send(:document_count_text)).to eq("Aucun document")
      end
    end

    context 'when folder has documents' do
      before do
        create_list(:document, 3, folder: folder, space: space)
      end

      it 'displays correct document count' do
        expect(component.send(:document_count_text)).to eq("3 document")
      end
    end
  end

  describe 'children count display' do
    context 'when folder has no children' do
      it 'returns nil' do
        expect(component.send(:children_count_text)).to be_nil
      end
    end

    context 'when folder has children' do
      before do
        create_list(:folder, 2, space: space, parent: folder)
      end

      it 'displays correct children count' do
        expect(component.send(:children_count_text)).to eq("2 sous-dossier")
      end
    end
  end

  describe 'permissions and actions' do
    let(:folder_policy) { double('FolderPolicy') }

    before do
      allow(Pundit).to receive(:policy).with(user, folder).and_return(folder_policy)
    end

    context 'when user can update folder' do
      before do
        allow(folder_policy).to receive(:update?).and_return(true)
        allow(folder_policy).to receive(:admin?).and_return(false)
        allow(folder_policy).to receive(:destroy?).and_return(false)
      end

      it 'includes rename and move actions' do
        actions = component.send(:folder_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Renommer", "Déplacer")
      end
    end

    context 'when user can admin folder' do
      before do
        allow(folder_policy).to receive(:update?).and_return(false)
        allow(folder_policy).to receive(:admin?).and_return(true)
        allow(folder_policy).to receive(:destroy?).and_return(false)
      end

      it 'includes manage permissions action' do
        actions = component.send(:folder_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Gérer les droits")
      end
    end

    context 'when user can destroy folder' do
      before do
        allow(folder_policy).to receive(:update?).and_return(false)
        allow(folder_policy).to receive(:admin?).and_return(false)
        allow(folder_policy).to receive(:destroy?).and_return(true)
      end

      it 'includes delete action' do
        actions = component.send(:folder_actions)
        action_labels = actions.map { |a| a[:label] }
        
        expect(action_labels).to include("Supprimer")
      end

      it 'marks delete action as dangerous' do
        actions = component.send(:folder_actions)
        delete_action = actions.find { |a| a[:label] == "Supprimer" }
        
        expect(delete_action[:danger]).to be(true)
      end
    end

    context 'when user has no special permissions' do
      before do
        allow(folder_policy).to receive(:update?).and_return(false)
        allow(folder_policy).to receive(:admin?).and_return(false)
        allow(folder_policy).to receive(:destroy?).and_return(false)
      end

      it 'only includes basic view action' do
        actions = component.send(:folder_actions)
        non_divider_actions = actions.reject { |a| a[:divider] }
        
        expect(non_divider_actions.size).to eq(1)
        expect(non_divider_actions.first[:label]).to eq("Ouvrir")
      end
    end
  end

  describe 'quick actions' do
    let(:folder_policy) { double('FolderPolicy') }

    before do
      allow(Pundit).to receive(:policy).with(user, folder).and_return(folder_policy)
    end

    context 'when user has admin rights' do
      before do
        allow(folder_policy).to receive(:admin?).and_return(true)
        allow(folder_policy).to receive(:update?).and_return(false)
      end

      it 'includes manage permissions in quick actions' do
        quick_actions = component.send(:quick_actions)
        expect(quick_actions.any? { |a| a[:icon] == "lock-closed" }).to be(true)
      end
    end

    context 'when user has update rights' do
      before do
        allow(folder_policy).to receive(:admin?).and_return(false)
        allow(folder_policy).to receive(:update?).and_return(true)
      end

      it 'includes rename in quick actions' do
        quick_actions = component.send(:quick_actions)
        expect(quick_actions.any? { |a| a[:icon] == "pencil" }).to be(true)
      end
    end
  end

  describe 'CSS classes and styling' do
    it 'includes draggable class when draggable' do
      expect(component.send(:card_classes)).to include('draggable')
    end

    it 'excludes draggable class when not draggable' do
      component = described_class.new(folder: folder, current_user: user, draggable: false)
      expect(component.send(:card_classes)).not_to include('draggable')
    end

    it 'includes proper folder icon classes' do
      icon_classes = component.send(:folder_icon_classes)
      expect(icon_classes).to include('text-blue-500', 'group-hover:text-blue-600')
    end
  end

  describe 'formatted dates' do
    context 'when folder was updated recently' do
      before do
        folder.update!(updated_at: 2.hours.ago)
      end

      it 'shows relative time with "ago" suffix' do
        result = component.send(:formatted_updated_at)
        expect(result).to match(/ago$/)
        expect(result).to include("heure")
      end
    end

    context 'when folder was updated long ago' do
      before do
        folder.update!(updated_at: 2.weeks.ago)
      end

      it 'shows formatted date' do
        result = component.send(:formatted_updated_at)
        expect(result).to match(/\d{2}\/\d{2}\/\d{4}|\d{1,2}\s\w+\s\d{2}:\d{2}/)
      end
    end
  end

  describe 'accessibility' do
    let(:rendered_component) { render_inline(component) }

    it 'includes screen reader text for folder link' do
      expect(rendered_component.text).to include("Ouvrir #{folder.name}")
    end

    it 'includes proper ARIA labels and titles' do
      expect(rendered_component.to_html).to include('title=')
    end

    it 'includes focus management for keyboard navigation' do
      expect(rendered_component.to_html).to include('focus:ring-2')
    end
  end

  describe 'empty states' do
    context 'when show_actions is false' do
      let(:component) { described_class.new(folder: folder, current_user: user, show_actions: false) }
      let(:rendered_component) { render_inline(component) }

      it 'does not show action buttons' do
        expect(rendered_component.to_html).not_to include('data-dropdown-target="menu"')
      end
    end

    context 'when user is nil' do
      let(:component) { described_class.new(folder: folder, current_user: nil) }

      it 'handles missing user gracefully' do
        expect { component.send(:folder_actions) }.not_to raise_error
        expect(component.send(:can?, :update, folder)).to be(false)
      end
    end
  end
end