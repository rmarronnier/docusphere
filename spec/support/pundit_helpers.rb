module PunditHelpers
  extend RSpec::Matchers::DSL
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def permissions(*actions, &block)
      actions.each do |action|
        describe "#{action}?" do
          instance_eval(&block)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include PunditHelpers, type: :policy
  
  # Chargez le fichier pundit_matchers
  Dir[Rails.root.join('spec/support/pundit_matchers.rb')].each { |f| require f }
end