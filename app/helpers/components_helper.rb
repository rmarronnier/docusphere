module ComponentsHelper
  # Layout helpers
  def page_wrapper(max_width: "7xl", with_navbar: true, &block)
    render Layout::PageWrapperComponent.new(max_width: max_width, with_navbar: with_navbar), &block
  end
  
  def page_header(title:, description: nil, &block)
    render Layout::PageHeaderComponent.new(title: title, description: description), &block
  end
  
  def card_grid(columns: { sm: 2, lg: 3, xl: 4 }, gap: 4, &block)
    render Layout::CardGridComponent.new(columns: columns, gap: gap), &block
  end
  
  # UI helpers
  def empty_state(title:, description: nil, icon: nil, &block)
    render Ui::EmptyStateComponent.new(title: title, description: description, icon: icon), &block
  end
  
  def user_avatar(user:, size: "md", show_tooltip: false)
    render Ui::UserAvatarComponent.new(user: user, size: size, show_tooltip: show_tooltip)
  end
  
  def data_table(responsive: true, &block)
    render Ui::DataTableComponent.new(responsive: responsive), &block
  end
  
  def dropdown(trigger_text: nil, trigger_icon: nil, position: "right", &block)
    render Ui::DropdownComponent.new(trigger_text: trigger_text, trigger_icon: trigger_icon, position: position), &block
  end
  
  def action_dropdown(actions:, **options)
    render Ui::ActionDropdownComponent.new(actions: actions, **options)
  end
  
  def notification(type: :info, title: nil, dismissible: true, &block)
    render Ui::NotificationComponent.new(type: type, title: title, dismissible: dismissible), &block
  end
  
  def description_list(title: nil)
    render Ui::DescriptionListComponent.new(title: title)
  end
  
  # Form helpers
  def form_errors(model)
    render Forms::FormErrorsComponent.new(model: model) if model.errors.any?
  end
  
  def search_form(url:, placeholder: "Rechercher...", value: nil, param_name: :search, submit_text: "Rechercher")
    render Forms::SearchFormComponent.new(
      url: url,
      placeholder: placeholder,
      value: value,
      param_name: param_name,
      submit_text: submit_text
    )
  end
  
  # Navigation helpers
  def breadcrumb(items:)
    render Navigation::BreadcrumbComponent.new(items: items)
  end
end