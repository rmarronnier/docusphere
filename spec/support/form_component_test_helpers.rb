module FormComponentTestHelpers
  def setup_form_builder(model_attributes = {})
    # Create a model with ActiveModel::Model included
    model_class = Class.new do
      include ActiveModel::Model
      
      # Define accessors for all provided attributes
      model_attributes.keys.each do |attr|
        attr_accessor attr
      end
      
      def self.name
        "TestModel"
      end
    end
    
    # Create instance with provided attributes
    model = model_class.new
    model_attributes.each do |key, value|
      model.send("#{key}=", value)
    end
    
    # Use a simple view context for testing
    view_context = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    
    # Create form builder with view context
    ActionView::Helpers::FormBuilder.new(:test_model, model, view_context, {})
  end
end

RSpec.configure do |config|
  config.include FormComponentTestHelpers, type: :component
end