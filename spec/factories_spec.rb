require 'rails_helper'

RSpec.describe "Factories" do
  # Get all factory names
  FactoryBot.factories.map(&:name).each do |factory_name|
    context "#{factory_name} factory" do
      it "creates a valid instance" do
        # Skip factories that require special setup
        skip_factories = []
        
        skip "Requires special setup" if skip_factories.include?(factory_name)
        
        # Create the factory and check if it's valid
        instance = build(factory_name)
        
        if instance.respond_to?(:valid?)
          expect(instance.valid?).to be(true), -> {
            "Expected #{factory_name} to be valid, but got errors: #{instance.errors.full_messages.join(', ')}"
          }
        end
      end
    end
  end
end