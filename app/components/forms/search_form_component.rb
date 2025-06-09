class Forms::SearchFormComponent < ApplicationComponent
  def initialize(url:, method: :get, placeholder: "Rechercher...", value: nil, param_name: :search, submit_text: "Rechercher")
    @url = url
    @method = method
    @placeholder = placeholder
    @value = value
    @param_name = param_name
    @submit_text = submit_text
  end

  private

  attr_reader :url, :method, :placeholder, :value, :param_name, :submit_text
end