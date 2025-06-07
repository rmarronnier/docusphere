class ApplicationComponent < ViewComponent::Base
  # Configuration de base pour tous les composants
  
  private
  
  def current_user
    helpers.current_user
  end
  
  def can?(*args)
    helpers.can?(*args) if helpers.respond_to?(:can?)
  end
end