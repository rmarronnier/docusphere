# frozen_string_literal: true

module Documents
  module Viewers
    class TextViewerComponent < ViewComponent::Base
      include ApplicationHelper
      
      def initialize(document:, show_actions: true)
        @document = document
        @show_actions = show_actions
      end
      
      private
      
      attr_reader :document, :show_actions
      
      def text_content
        if document.file.attached?
          document.file.download
        else
          "No content available"
        end
      rescue => e
        "Error loading file: #{e.message}"
      end
      
      def file_extension
        document.file_extension&.downcase || 'txt'
      end
      
      def syntax_language
        case file_extension
        when 'js', 'javascript' then 'javascript'
        when 'rb', 'ruby' then 'ruby'
        when 'py', 'python' then 'python'
        when 'json' then 'json'
        when 'xml' then 'xml'
        when 'html', 'htm' then 'html'
        when 'css' then 'css'
        when 'sql' then 'sql'
        when 'sh', 'bash' then 'bash'
        when 'yml', 'yaml' then 'yaml'
        else 'plaintext'
        end
      end
      
      def is_code_file?
        %w[js rb py json xml html css sql sh yml yaml].include?(file_extension)
      end
      
      def download_button
        link_to helpers.ged_download_document_path(document), 
                class: "btn btn-sm btn-secondary",
                data: { turbo_frame: "_top" } do
          concat render(Ui::IconComponent.new(name: :arrow_down_tray, size: 4, css_class: "mr-1"))
          concat "Télécharger"
        end
      end
    end
  end
end