class Forms::FormErrorsComponent < ApplicationComponent
  def initialize(model:)
    @model = model
  end

  def render?
    @model.errors.any?
  end

  private

  attr_reader :model
  
  def error_count_message
    count = model.errors.count
    verb = count == 1 ? 'empêche' : 'empêchent'
    "#{helpers.pluralize(count, 'erreur')} #{verb} l'enregistrement"
  end
end