module ViewComponentTestHelpers
  def mock_component_helpers(component_class, user: nil, additional_helpers: {})
    user ||= create(:user)
    
    base_helpers = {
      current_user: user,
      user_signed_in?: true,
      protect_against_forgery?: false,
      policy: ->(record) {
        double(
          index?: true,
          show?: true,
          create?: true,
          update?: true,
          destroy?: true,
          edit?: true,
          new?: true,
          share?: true
        )
      },
      link_to: ->(text, path, options = {}) { 
        attrs = options.map{|k,v| k == :data ? v.map{|dk,dv| "data-#{dk.to_s.dasherize}='#{dv}'"}.join(' ') : "#{k}='#{v}'"}.join(' ')
        %Q(<a href="#{path}" #{attrs}>#{text}</a>).html_safe 
      },
      button_to: ->(text, path, options = {}) {
        method = options[:method] || 'post'
        css_class = options[:class] || ''
        data_attrs = options[:data]&.map { |k, v| "data-#{k.to_s.dasherize}='#{v}'" }&.join(' ') || ''
        %Q(<form action="#{path}" method="#{method}" class="button_to"><button type="submit" class="#{css_class}" #{data_attrs}>#{text}</button></form>).html_safe
      },
      render: '',
      l: ->(date, options = {}) { 
        return '' unless date
        date.strftime(options[:format] == :short ? '%d/%m/%Y' : '%d/%m/%Y %H:%M')
      },
      t: ->(key, options = {}) { 
        # Handle specific translations
        case key
        when 'documents.status.published'
          'Publié'
        when 'documents.status.draft'
          'Brouillon'
        when 'documents.status.locked'
          'Verrouillé'
        when 'documents.status.archived'
          'Archivé'
        else
          key.to_s.humanize
        end
      },
      number_to_currency: ->(number, options = {}) {
        unit = options[:unit] || '€'
        delimiter = options[:delimiter] || ' '
        separator = options[:separator] || ','
        "#{unit} #{number.to_s.gsub('.', separator).gsub(/(\d)(?=(\d{3})+(?!\d))/, "\\1#{delimiter}")}"
      },
      content_tag: ->(tag, content = nil, options = {}, &block) {
        content_html = block_given? ? yield : content
        attrs = options.map{|k,v| "#{k}='#{v}'"}.join(' ')
        %Q(<#{tag}#{attrs.empty? ? '' : ' ' + attrs}>#{content_html}</#{tag}>).html_safe
      },
      concat: ->(content) { content },
      tag: OpenStruct.new({
        div: ->(content = nil, options = {}, &block) {
          content_html = block_given? ? capture(&block) : content
          %Q(<div #{options.map{|k,v| "#{k}='#{v}'"}.join(' ')}>#{content_html}</div>).html_safe
        },
        span: ->(content = nil, options = {}) {
          %Q(<span #{options.map{|k,v| "#{k}='#{v}'"}.join(' ')}>#{content}</span>).html_safe
        }
      }),
      # URL helpers
      document_path: ->(doc, options = {}) { 
        format = options[:format]
        path = "/documents/#{doc.id}"
        format ? "#{path}.#{format}" : path
      },
      edit_document_path: ->(doc) { "/documents/#{doc.id}/edit" },
      documents_path: '/documents',
      new_document_share_path: ->(options = {}) { "/documents/#{options[:document_id]}/shares/new" },
      ged_space_path: ->(space) { "/ged/spaces/#{space.id}" },
      ged_folder_path: ->(folder) { "/ged/folders/#{folder.id}" },
      root_path: '/',
      ged_path: '/ged',
      search_path: '/search',
      new_document_path: '/documents/new',
      new_user_session_path: '/users/sign_in',
      new_user_registration_path: '/users/sign_up',
      search_suggestions_path: '/search/suggestions',
      form_with: ->(url:, method: :get, local: true, data: {}, &block) {
        form_html = "<form action=\"#{url}\" method=\"#{method}\" #{ data.map{|k,v| "data-#{k.to_s.dasherize}='#{v}'"}.join(' ') }>"
        if block_given?
          form_html << yield(OpenStruct.new(text_field: ->(name, **options) {
            "<input type=\"text\" name=\"#{name}\" #{ options.map{|k,v| k == :data ? v.map{|dk,dv| "data-#{dk.to_s.dasherize}='#{dv}'"}.join(' ') : "#{k}='#{v}'"}.join(' ') }/>"
          }))
        end
        form_html << "</form>"
        form_html.html_safe
      },
      # View helpers
      time_ago_in_words: ->(time) { "#{((Time.current - time) / 1.day).to_i} days ago" },
      number_to_human_size: ->(size) { "#{(size / 1024.0 / 1024.0).round(2)} MB" },
      pluralize: ->(count, singular, plural = nil) {
        if singular == 'erreur'
          "#{count} #{count == 1 ? 'erreur' : 'erreurs'}"
        else
          plural ||= "#{singular}s"
          "#{count} #{count == 1 ? singular : plural}"
        end
      }
    }
    
    helpers = base_helpers.merge(additional_helpers)
    
    # Create a proper double that responds to all helper methods
    helpers_double = double('helpers')
    helpers.each do |method_name, implementation|
      if implementation.respond_to?(:call)
        allow(helpers_double).to receive(method_name) do |*args, &block|
          implementation.call(*args, &block)
        end
      else
        allow(helpers_double).to receive(method_name).and_return(implementation)
      end
    end
    
    without_partial_double_verification do
      allow_any_instance_of(component_class).to receive(:helpers).and_return(helpers_double)
    end
  end
end

RSpec.configure do |config|
  config.include ViewComponentTestHelpers, type: :component
end