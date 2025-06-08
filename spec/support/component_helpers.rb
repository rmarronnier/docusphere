module ComponentHelpers
  def mock_view_component_helpers(user:, additional_methods: {})
    spaces = Space.where(organization: user.organization)
    tags = Tag.where(organization: user.organization)
    folders = Folder.joins(:space).where(spaces: { organization: user.organization })
    
    helpers_double = double(
      current_user: user,
      policy: double(create?: true, update?: true, admin?: true)
    )
    
    allow(helpers_double).to receive(:policy_scope) do |scope|
      case scope.name
      when "Space"
        spaces
      when "Tag"
        tags
      when "Folder"
        folders
      else
        scope.none
      end
    end
    
    # Add any additional methods
    additional_methods.each do |method, value|
      allow(helpers_double).to receive(method).and_return(value)
    end
    
    allow_any_instance_of(described_class).to receive(:helpers).and_return(helpers_double)
  end
end

RSpec.configure do |config|
  config.include ComponentHelpers, type: :component
end