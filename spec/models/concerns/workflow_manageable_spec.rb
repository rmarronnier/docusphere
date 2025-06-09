require 'rails_helper'

RSpec.describe WorkflowManageable, type: :concern do
  # NOTE: This concern is used by ImmoPromo models (Permit, Phase, Task)
  # These models have their own specific tests that cover the concern functionality
  # This spec is kept as a placeholder for future reference
  
  pending "WorkflowManageable is tested through the models that include it (Immo::Promo::Permit, Phase, Task)"
end