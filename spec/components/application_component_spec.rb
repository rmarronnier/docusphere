require 'rails_helper'

RSpec.describe ApplicationComponent, type: :component do
  # Create a test subclass for testing
  let(:test_component_class) do
    Class.new(described_class) do
      def self.name
        "TestApplicationComponent"
      end
      
      def call
        content_tag :div do
          concat "User: #{current_user&.first_name} #{current_user&.last_name}"
          concat " Can edit: #{can?(:edit, :document)}"
        end
      end
    end
  end
  
  let(:user) { create(:user, first_name: 'Test', last_name: 'User') }
  let(:component) { test_component_class.new }
  
  describe 'inheritance' do
    it 'inherits from ViewComponent::Base' do
      expect(described_class).to be < ViewComponent::Base
    end
    
    it 'is the base class for all application components' do
      expect(BaseCardComponent).to be < described_class
      expect(BaseFormComponent).to be < described_class
      expect(BaseListComponent).to be < described_class
      expect(BaseModalComponent).to be < described_class
      expect(BaseTableComponent).to be < described_class
    end
  end
  
  describe '#current_user' do
    before do
      mock_component_helpers(test_component_class, user: user, additional_helpers: {
        can?: ->(*args) { true }
      })
    end
    
    it 'delegates to helpers.current_user' do
      render_inline(component)
      expect(page).to have_text('User: Test User')
    end
    
    context 'when no user is signed in' do
      it 'handles nil user gracefully' do
        # Test the method directly instead of through rendering
        allow(component).to receive(:helpers).and_return(double(current_user: nil))
        expect(component.send(:current_user)).to be_nil
      end
    end
  end
  
  describe '#can?' do
    before do
      mock_component_helpers(test_component_class, user: user, additional_helpers: {
        can?: ->(*args) { true }
      })
    end
    
    it 'delegates to helpers.can?' do
      render_inline(component)
      expect(page).to have_text('Can edit: true')
    end
    
    context 'when helpers does not respond to can?' do
      before do
        mock_component_helpers(test_component_class, user: user, additional_helpers: {
          can?: nil
        })
        allow(component.helpers).to receive(:respond_to?).with(:can?).and_return(false)
      end
      
      it 'returns nil' do
        expect(component.send(:can?, :edit, :document)).to be_nil
      end
    end
  end
  
  describe 'as base component' do
    before do
      mock_component_helpers(test_component_class, user: user, additional_helpers: {
        can?: ->(*args) { true }
      })
    end
    
    it 'provides access to helpers' do
      expect(component.helpers).to respond_to(:current_user)
      expect(component.helpers).to respond_to(:link_to)
      expect(component.helpers).to respond_to(:t)
    end
    
    it 'can be instantiated directly' do
      expect { described_class.new }.not_to raise_error
    end
    
    it 'raises error when rendering without implementing call method' do
      base_component = described_class.new
      mock_component_helpers(described_class)
      expect { render_inline(base_component) }.to raise_error(ViewComponent::TemplateError)
    end
  end
end