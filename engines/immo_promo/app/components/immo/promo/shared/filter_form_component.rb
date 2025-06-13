class Immo::Promo::Shared::FilterFormComponent < ViewComponent::Base
  attr_reader :filters, :action_url, :method, :current_params, :auto_submit, :show_reset

  def initialize(filters:, action_url:, method: :get, current_params: {}, auto_submit: true, show_reset: true, css_class: "")
    @filters = filters
    @action_url = action_url
    @method = method
    @current_params = current_params
    @auto_submit = auto_submit
    @show_reset = show_reset
    @css_class = css_class
  end

  def css_class
    classes = ["bg-white shadow rounded-lg p-4"]
    classes << @css_class if @css_class.present?
    classes.join(" ")
  end

  def form_css_classes
    classes = ["flex flex-wrap gap-4 items-end"]
    classes << "filter-form" if auto_submit
    classes.join(" ")
  end

  def stimulus_attributes
    return {} unless auto_submit
    {
      data: {
        controller: "filter-form",
        "filter-form-auto-submit-value": "true"
      }
    }
  end

  def filter_input_css_classes
    "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
  end

  def filter_label_css_classes
    "block text-sm font-medium text-gray-700 mb-1"
  end

  def selected_value_for(filter)
    name = filter[:name]
    current_params[name] || current_params[name.to_s] || current_params[name.to_sym] || ""
  end

  def has_active_filters?
    filters.any? { |filter| selected_value_for(filter).present? }
  end

  def reset_url
    # Remove filter parameters but keep other params like page, per_page
    preserved_params = current_params.dup
    filter_param_names.each do |param_name|
      preserved_params.delete(param_name)
      preserved_params.delete(param_name.to_s)
      preserved_params.delete(param_name.to_sym)
    end
    
    if preserved_params.any?
      "#{action_url}?#{preserved_params.to_query}"
    else
      action_url
    end
  end

  private

  def filter_param_names
    filters.map { |filter| filter[:name] }
  end
end