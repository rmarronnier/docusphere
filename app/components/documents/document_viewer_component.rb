# frozen_string_literal: true

module Documents
  class DocumentViewerComponent < ViewComponent::Base
    include ApplicationHelper
    
    def initialize(document:, show_actions: true, show_sidebar: true, context: nil)
      @document = document
      @show_actions = show_actions
      @show_sidebar = show_sidebar
      @context = context # Can be :project, :validation, :workflow, etc.
    end

    private

    attr_reader :document, :show_actions, :show_sidebar, :context

    def viewer_content
      case document.content_type_category
      when :pdf
        pdf_viewer
      when :image
        image_viewer
      when :video
        video_player
      when :office
        office_viewer
      when :text
        text_viewer
      when :cad
        cad_viewer
      when :archive
        archive_viewer
      else
        fallback_viewer
      end
    end

    def pdf_viewer
      content_tag(:div, class: "pdf-viewer-container h-full", data: { controller: "pdf-viewer" }) do
        content_tag(:div, class: "pdf-toolbar bg-gray-100 border-b flex items-center justify-between p-2") do
          concat pdf_navigation_controls
          concat pdf_zoom_controls
          concat pdf_view_controls
        end +
        content_tag(:iframe,
          nil,
          src: pdf_viewer_url,
          class: "w-full h-full border-0",
          loading: "lazy",
          title: "PDF Viewer: #{document.name}",
          data: { "pdf-viewer-target": "frame" }
        )
      end
    end

    def image_viewer
      content_tag(:div, class: "image-viewer-container h-full bg-gray-900", data: { controller: "image-viewer" }) do
        content_tag(:div, class: "image-toolbar bg-gray-800 border-b flex items-center justify-between p-2 text-white") do
          concat image_navigation_controls
          concat image_zoom_controls
          concat image_transform_controls
        end +
        content_tag(:div, class: "image-viewport relative h-full overflow-hidden flex items-center justify-center") do
          image_tag(
            preview_url(:original),
            class: "max-w-full max-h-full object-contain",
            alt: document.name,
            loading: "lazy",
            data: { 
              "image-viewer-target": "image",
              action: "wheel->image-viewer#zoom"
            }
          )
        end
      end
    end

    def video_player
      content_tag(:div, class: "video-player-container h-full bg-black flex flex-col") do
        content_tag(:div, class: "video-viewport flex-1 flex items-center justify-center") do
          video_tag(
            rails_blob_path(document.file),
            controls: true,
            class: "max-w-full max-h-full",
            preload: "metadata",
            poster: document.thumbnail_url,
            data: { controller: "video-player" }
          )
        end +
        video_controls
      end
    end

    def office_viewer
      if document.preview.attached?
        # Show preview images with navigation
        multi_page_viewer
      else
        # Use Office Online viewer or fallback
        office_online_viewer || office_fallback_viewer
      end
    end

    def text_viewer
      content_tag(:div, class: "text-viewer-container h-full flex flex-col", data: { controller: "text-viewer" }) do
        text_toolbar +
        content_tag(:div, class: "text-content flex-1 overflow-auto bg-gray-50") do
          content_tag(:pre, class: "p-6 text-sm font-mono", data: { "text-viewer-target": "content" }) do
            load_text_content
          end
        end
      end
    end

    def cad_viewer
      content_tag(:div, class: "cad-viewer-container h-full") do
        if document.preview.attached?
          # Show CAD preview image
          image_viewer
        else
          cad_fallback_viewer
        end
      end
    end

    def archive_viewer
      content_tag(:div, class: "archive-viewer-container h-full", data: { controller: "archive-viewer" }) do
        archive_toolbar +
        content_tag(:div, class: "archive-contents flex-1 overflow-auto p-4") do
          archive_file_list
        end
      end
    end

    def fallback_viewer
      content_tag(:div, class: "fallback-viewer flex flex-col items-center justify-center h-full p-8 text-center bg-gray-50") do
        concat(document_icon(size: :large))
        concat(content_tag(:h3, document.name, class: "mt-4 text-xl font-semibold text-gray-900"))
        concat(file_info_details)
        concat(content_tag(:p, "Preview not available for this file type", class: "mt-4 text-sm text-gray-600"))
        concat(viewer_actions) if show_actions
      end
    end

    # Multi-page viewer for documents with multiple preview pages
    def multi_page_viewer
      content_tag(:div, class: "multi-page-viewer h-full", data: { controller: "multi-page-viewer" }) do
        page_navigation_toolbar +
        content_tag(:div, class: "page-viewport flex-1 overflow-hidden bg-gray-100 flex items-center justify-center") do
          if document.preview_pages.any?
            image_tag(
              document.preview_pages.first.url,
              class: "max-w-full max-h-full object-contain shadow-lg",
              data: { 
                "multi-page-viewer-target": "currentPage",
                pages: document.preview_pages.map(&:url).to_json
              }
            )
          end
        end
      end
    end

    # Office Online Viewer integration
    def office_online_viewer
      return nil unless document.office_viewable?
      
      content_tag(:div, class: "office-online-viewer h-full") do
        content_tag(:iframe,
          nil,
          src: office_viewer_url,
          class: "w-full h-full border-0",
          frameborder: "0",
          allowfullscreen: true
        )
      end
    end

    # Toolbar components
    def pdf_navigation_controls
      content_tag(:div, class: "flex items-center space-x-2") do
        concat icon_button("chevron-left", "Previous Page", data: { action: "click->pdf-viewer#previousPage" })
        concat content_tag(:span, "Page ", class: "text-sm text-gray-600")
        concat content_tag(:input, nil, 
          type: "number", 
          value: "1", 
          min: "1",
          class: "w-12 px-2 py-1 text-sm border rounded",
          data: { "pdf-viewer-target": "pageInput", action: "change->pdf-viewer#goToPage" }
        )
        concat content_tag(:span, " of ", class: "text-sm text-gray-600")
        concat content_tag(:span, "1", class: "text-sm text-gray-600", data: { "pdf-viewer-target": "totalPages" })
        concat icon_button("chevron-right", "Next Page", data: { action: "click->pdf-viewer#nextPage" })
      end
    end

    def pdf_zoom_controls
      content_tag(:div, class: "flex items-center space-x-2") do
        concat icon_button("minus", "Zoom Out", data: { action: "click->pdf-viewer#zoomOut" })
        concat content_tag(:select, 
          options_for_select([
            ["Auto", "auto"],
            ["50%", "0.5"],
            ["75%", "0.75"],
            ["100%", "1"],
            ["125%", "1.25"],
            ["150%", "1.5"],
            ["200%", "2"],
            ["Fit Width", "fit-width"],
            ["Fit Page", "fit-page"]
          ], "auto"),
          class: "px-2 py-1 text-sm border rounded",
          data: { "pdf-viewer-target": "zoomSelect", action: "change->pdf-viewer#setZoom" }
        )
        concat icon_button("plus", "Zoom In", data: { action: "click->pdf-viewer#zoomIn" })
      end
    end

    def pdf_view_controls
      content_tag(:div, class: "flex items-center space-x-2") do
        concat icon_button("arrows-pointing-out", "Fullscreen", data: { action: "click->pdf-viewer#fullscreen" })
        concat icon_button("printer", "Print", data: { action: "click->pdf-viewer#print" })
        concat download_button if show_actions
      end
    end

    def image_navigation_controls
      if document.part_of_collection?
        content_tag(:div, class: "flex items-center space-x-2") do
          concat icon_button("chevron-left", "Previous", data: { action: "click->image-viewer#previous" })
          concat content_tag(:span, "#{document.collection_index + 1} / #{document.collection_count}", class: "text-sm")
          concat icon_button("chevron-right", "Next", data: { action: "click->image-viewer#next" })
        end
      else
        content_tag(:div, "")
      end
    end

    def image_zoom_controls
      content_tag(:div, class: "flex items-center space-x-2") do
        concat icon_button("minus", "Zoom Out", data: { action: "click->image-viewer#zoomOut" })
        concat content_tag(:span, "100%", class: "text-sm w-12 text-center", data: { "image-viewer-target": "zoomLevel" })
        concat icon_button("plus", "Zoom In", data: { action: "click->image-viewer#zoomIn" })
        concat icon_button("arrows-pointing-out", "Fit", data: { action: "click->image-viewer#fit" })
        concat icon_button("magnifying-glass-plus", "Actual Size", data: { action: "click->image-viewer#actualSize" })
      end
    end

    def image_transform_controls
      content_tag(:div, class: "flex items-center space-x-2") do
        concat icon_button("arrow-path", "Rotate", data: { action: "click->image-viewer#rotate" })
        concat icon_button("arrows-right-left", "Flip Horizontal", data: { action: "click->image-viewer#flipHorizontal" })
        concat icon_button("arrows-up-down", "Flip Vertical", data: { action: "click->image-viewer#flipVertical" })
      end
    end

    def text_toolbar
      content_tag(:div, class: "text-toolbar bg-gray-100 border-b flex items-center justify-between p-2") do
        content_tag(:div, class: "flex items-center space-x-2") do
          concat content_tag(:select,
            options_for_select([
              ["Plain Text", "plain"],
              ["Syntax Highlight", "syntax"],
              ["Line Numbers", "lines"],
              ["Word Wrap", "wrap"]
            ], "plain"),
            class: "px-2 py-1 text-sm border rounded",
            data: { action: "change->text-viewer#changeMode" }
          )
        end +
        content_tag(:div, class: "flex items-center space-x-2") do
          concat icon_button("magnifying-glass", "Search", data: { action: "click->text-viewer#toggleSearch" })
          concat icon_button("clipboard-document", "Copy All", data: { action: "click->text-viewer#copyAll" })
        end
      end
    end

    def viewer_actions
      content_tag(:div, class: "viewer-actions flex items-center justify-center gap-3 mt-6") do
        concat download_button
        concat open_in_new_tab_button if can_open_in_new_tab?
        concat share_button if policy(document).share?
        concat edit_button if policy(document).update?
      end
    end

    def contextual_actions
      return unless show_actions
      
      actions = []
      
      # Actions based on user profile type
      user_profile = helpers.current_user.active_profile
      
      if user_profile
        case user_profile.profile_type
        when 'direction'
          actions.concat(direction_actions)
        when 'chef_projet'
          actions.concat(project_manager_actions)
        when 'juriste'
          actions.concat(legal_actions)
        when 'architecte'
          actions.concat(architect_actions)
        when 'commercial'
          actions.concat(commercial_actions)
        when 'controleur'
          actions.concat(controller_actions)
        when 'expert_technique'
          actions.concat(technical_expert_actions)
        end
      end
      
      # Common actions available to all profiles
      actions.concat(common_actions)
      
      return if actions.empty?
      
      content_tag(:div, class: "contextual-actions flex flex-wrap gap-2 p-4 bg-gray-50 border-t") do
        safe_join(actions)
      end
    end
    
    def direction_actions
      actions = []
      actions << approve_button if policy(document).approve?
      actions << reject_button if policy(document).reject?
      actions << assign_button if policy(document).assign?
      actions << priority_button if can_set_priority?
      actions
    end
    
    def project_manager_actions
      actions = []
      actions << link_to_project_button if can_link_to_project?
      actions << assign_to_phase_button if document.project_linked?
      actions << request_validation_button if policy(document).request_validation?
      actions << distribute_button if policy(document).distribute?
      actions << planning_button if can_add_to_planning?
      actions
    end
    
    def legal_actions
      actions = []
      actions << validate_compliance_button if policy(document).validate_compliance?
      actions << add_legal_note_button if policy(document).annotate?
      actions << contract_review_button if document.contract?
      actions << archive_button if policy(document).archive?
      actions
    end
    
    def architect_actions
      actions = []
      actions << technical_review_button if policy(document).technical_review?
      actions << annotate_plan_button if document.cad_file? || document.plan?
      actions << request_modification_button if can_request_modification?
      actions << version_compare_button if document.versions.count > 1
      actions
    end
    
    def commercial_actions
      actions = []
      actions << share_with_client_button if policy(document).share_external?
      actions << add_to_proposal_button if can_add_to_proposal?
      actions << price_update_button if document.pricing_document?
      actions << client_feedback_button if document.client_visible?
      actions
    end
    
    def controller_actions
      actions = []
      actions << validate_button if policy(document).validate?
      actions << reject_button if policy(document).reject?
      actions << compliance_check_button if needs_compliance_check?
      actions << audit_trail_button if policy(document).view_audit?
      actions << report_issue_button
      actions
    end
    
    def technical_expert_actions
      actions = []
      actions << technical_validate_button if policy(document).technical_validate?
      actions << add_technical_note_button if policy(document).annotate?
      actions << specification_check_button if document.technical_document?
      actions << test_results_button if document.test_document?
      actions
    end
    
    def common_actions
      actions = []
      actions << annotate_button if policy(document).annotate?
      actions << bookmark_button
      actions << print_button
      actions << history_button if document.versions.any?
      actions << export_button if policy(document).export?
      actions
    end
    
    # Action buttons
    def approve_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700",
        data: { action: "click->document-viewer#approve" }
      ) do
        concat(heroicon("check", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Approuver")
      end
    end
    
    def reject_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-red-600 text-white text-sm rounded-lg hover:bg-red-700",
        data: { action: "click->document-viewer#reject" }
      ) do
        concat(heroicon("x-mark", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Rejeter")
      end
    end
    
    def validate_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700",
        data: { action: "click->document-viewer#validate" }
      ) do
        concat(heroicon("check-badge", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Valider")
      end
    end
    
    def request_validation_button
      link_to(
        new_document_validation_request_path(document),
        class: "inline-flex items-center px-3 py-2 bg-purple-600 text-white text-sm rounded-lg hover:bg-purple-700"
      ) do
        concat(heroicon("clipboard-document-check", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Demander validation")
      end
    end
    
    def annotate_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-yellow-600 text-white text-sm rounded-lg hover:bg-yellow-700",
        data: { action: "click->document-viewer#annotate" }
      ) do
        concat(heroicon("pencil-square", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Annoter")
      end
    end
    
    def link_to_project_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700",
        data: { action: "click->document-viewer#linkToProject" }
      ) do
        concat(heroicon("link", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Lier au projet")
      end
    end
    
    def assign_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-gray-600 text-white text-sm rounded-lg hover:bg-gray-700",
        data: { action: "click->document-viewer#assign" }
      ) do
        concat(heroicon("user-plus", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Assigner")
      end
    end
    
    def bookmark_button
      is_bookmarked = helpers.current_user.bookmarked_documents.exists?(document.id)
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 #{is_bookmarked ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-700'} text-sm rounded-lg hover:bg-gray-200",
        data: { action: "click->document-viewer#toggleBookmark" }
      ) do
        concat(heroicon("bookmark", variant: is_bookmarked ? :solid : :outline, options: { class: "w-4 h-4 mr-1.5" }))
        concat(is_bookmarked ? "Favori" : "Ajouter aux favoris")
      end
    end
    
    def history_button
      link_to(
        document_versions_path(document),
        class: "inline-flex items-center px-3 py-2 bg-gray-100 text-gray-700 text-sm rounded-lg hover:bg-gray-200",
        data: { turbo_frame: "document_sidebar" }
      ) do
        concat(heroicon("clock", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Historique")
      end
    end
    
    def print_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-gray-100 text-gray-700 text-sm rounded-lg hover:bg-gray-200",
        onclick: "window.print()"
      ) do
        concat(heroicon("printer", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Imprimer")
      end
    end
    
    def export_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-gray-100 text-gray-700 text-sm rounded-lg hover:bg-gray-200",
        data: { action: "click->document-viewer#export" }
      ) do
        concat(heroicon("arrow-down-on-square", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Exporter")
      end
    end
    
    # Additional action buttons for specific profiles
    def priority_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-orange-600 text-white text-sm rounded-lg hover:bg-orange-700",
        data: { action: "click->document-viewer#setPriority" }
      ) do
        concat(heroicon("flag", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Priorité")
      end
    end
    
    def assign_to_phase_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700",
        data: { action: "click->document-viewer#assignToPhase" }
      ) do
        concat(heroicon("folder-plus", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Assigner à une phase")
      end
    end
    
    def distribute_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-teal-600 text-white text-sm rounded-lg hover:bg-teal-700",
        data: { action: "click->document-viewer#distribute" }
      ) do
        concat(heroicon("paper-airplane", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Distribuer")
      end
    end
    
    def planning_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-pink-600 text-white text-sm rounded-lg hover:bg-pink-700",
        data: { action: "click->document-viewer#addToPlanning" }
      ) do
        concat(heroicon("calendar-days", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Ajouter au planning")
      end
    end
    
    def validate_compliance_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-emerald-600 text-white text-sm rounded-lg hover:bg-emerald-700",
        data: { action: "click->document-viewer#validateCompliance" }
      ) do
        concat(heroicon("shield-check", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Valider conformité")
      end
    end
    
    def add_legal_note_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-purple-600 text-white text-sm rounded-lg hover:bg-purple-700",
        data: { action: "click->document-viewer#addLegalNote" }
      ) do
        concat(heroicon("scale", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Note juridique")
      end
    end
    
    def contract_review_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700",
        data: { action: "click->document-viewer#reviewContract" }
      ) do
        concat(heroicon("document-check", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Réviser contrat")
      end
    end
    
    def archive_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-gray-600 text-white text-sm rounded-lg hover:bg-gray-700",
        data: { action: "click->document-viewer#archive" }
      ) do
        concat(heroicon("archive-box", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Archiver")
      end
    end
    
    def technical_review_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700",
        data: { action: "click->document-viewer#technicalReview" }
      ) do
        concat(heroicon("wrench-screwdriver", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Révision technique")
      end
    end
    
    def annotate_plan_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-cyan-600 text-white text-sm rounded-lg hover:bg-cyan-700",
        data: { action: "click->document-viewer#annotatePlan" }
      ) do
        concat(heroicon("pencil-square", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Annoter plan")
      end
    end
    
    def request_modification_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-amber-600 text-white text-sm rounded-lg hover:bg-amber-700",
        data: { action: "click->document-viewer#requestModification" }
      ) do
        concat(heroicon("arrow-path", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Demander modification")
      end
    end
    
    def version_compare_button
      link_to(
        compare_document_versions_path(document),
        class: "inline-flex items-center px-3 py-2 bg-violet-600 text-white text-sm rounded-lg hover:bg-violet-700"
      ) do
        concat(heroicon("arrows-right-left", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Comparer versions")
      end
    end
    
    def share_with_client_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700",
        data: { action: "click->document-viewer#shareWithClient" }
      ) do
        concat(heroicon("share", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Partager client")
      end
    end
    
    def add_to_proposal_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700",
        data: { action: "click->document-viewer#addToProposal" }
      ) do
        concat(heroicon("document-plus", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Ajouter à proposition")
      end
    end
    
    def price_update_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700",
        data: { action: "click->document-viewer#updatePrice" }
      ) do
        concat(heroicon("currency-euro", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Mettre à jour prix")
      end
    end
    
    def client_feedback_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-yellow-600 text-white text-sm rounded-lg hover:bg-yellow-700",
        data: { action: "click->document-viewer#clientFeedback" }
      ) do
        concat(heroicon("chat-bubble-left-right", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Retour client")
      end
    end
    
    def compliance_check_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-red-600 text-white text-sm rounded-lg hover:bg-red-700",
        data: { action: "click->document-viewer#checkCompliance" }
      ) do
        concat(heroicon("clipboard-document-check", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Vérifier conformité")
      end
    end
    
    def audit_trail_button
      link_to(
        document_audit_trail_path(document),
        class: "inline-flex items-center px-3 py-2 bg-gray-600 text-white text-sm rounded-lg hover:bg-gray-700"
      ) do
        concat(heroicon("document-magnifying-glass", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Piste d'audit")
      end
    end
    
    def report_issue_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-red-600 text-white text-sm rounded-lg hover:bg-red-700",
        data: { action: "click->document-viewer#reportIssue" }
      ) do
        concat(heroicon("exclamation-triangle", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Signaler problème")
      end
    end
    
    def technical_validate_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-green-600 text-white text-sm rounded-lg hover:bg-green-700",
        data: { action: "click->document-viewer#technicalValidate" }
      ) do
        concat(heroicon("check-badge", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Validation technique")
      end
    end
    
    def add_technical_note_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700",
        data: { action: "click->document-viewer#addTechnicalNote" }
      ) do
        concat(heroicon("beaker", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Note technique")
      end
    end
    
    def specification_check_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-purple-600 text-white text-sm rounded-lg hover:bg-purple-700",
        data: { action: "click->document-viewer#checkSpecification" }
      ) do
        concat(heroicon("clipboard-document-list", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Vérifier spécifications")
      end
    end
    
    def test_results_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-3 py-2 bg-teal-600 text-white text-sm rounded-lg hover:bg-teal-700",
        data: { action: "click->document-viewer#viewTestResults" }
      ) do
        concat(heroicon("chart-bar", variant: :solid, options: { class: "w-4 h-4 mr-1.5" }))
        concat("Résultats tests")
      end
    end
    
    # Helper methods for checking capabilities
    def can_link_to_project?
      !document.project_linked? && policy(document).link_to_project?
    end
    
    def can_set_priority?
      policy(document).set_priority?
    end
    
    def can_add_to_planning?
      policy(document).add_to_planning?
    end
    
    def can_request_modification?
      policy(document).request_modification?
    end
    
    def can_add_to_proposal?
      policy(document).add_to_proposal?
    end
    
    def needs_compliance_check?
      document.compliance_required? && !document.compliance_validated?
    end
    
    # Path helpers
    def new_document_validation_request_path(doc)
      helpers.new_ged_document_validation_path(doc)
    end
    
    def document_versions_path(doc)
      helpers.ged_document_versions_path(doc)
    end
    
    def compare_document_versions_path(doc)
      helpers.ged_compare_document_versions_path(doc)
    end
    
    def document_audit_trail_path(doc)
      helpers.ged_audit_trail_document_path(doc)
    end

    # Helper methods
    def document_icon(size: :medium)
      size_class = case size
      when :small then "w-12 h-12"
      when :medium then "w-16 h-16"
      when :large then "w-24 h-24"
      end
      
      if document.thumbnail.attached?
        image_tag(
          document.thumbnail,
          class: "#{size_class} object-cover rounded-lg shadow",
          alt: "Document thumbnail"
        )
      else
        content_tag(:div, class: "#{size_class} bg-gray-200 rounded-lg flex items-center justify-center") do
          heroicon("document", variant: :solid, options: { class: "w-1/2 h-1/2 text-gray-400" })
        end
      end
    end

    def file_info_details
      content_tag(:div, class: "file-info mt-4 space-y-1 text-sm text-gray-600") do
        concat content_tag(:div, "Type: #{document.file_extension&.upcase || 'Unknown'}")
        concat content_tag(:div, "Size: #{number_to_human_size(document.file.byte_size)}")
        concat content_tag(:div, "Uploaded: #{document.created_at.to_fs(:long)}")
        concat content_tag(:div, "Modified: #{time_ago_in_words(document.updated_at)} ago")
        concat content_tag(:div, "Version: #{document.current_version}") if document.versioned?
      end
    end

    def icon_button(icon_name, title, options = {})
      button_tag(
        type: "button",
        title: title,
        class: "p-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-200 rounded transition-colors " + (options[:class] || ""),
        **options.except(:class)
      ) do
        heroicon(icon_name, variant: :solid, options: { class: "w-5 h-5" })
      end
    end

    def download_button
      link_to(
        ged_download_document_path(document),
        class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors",
        data: { turbo: false }
      ) do
        concat(heroicon("arrow-down-tray", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Download")
      end
    end

    def open_in_new_tab_button
      link_to(
        rails_blob_path(document.file),
        target: "_blank",
        rel: "noopener",
        class: "inline-flex items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
      ) do
        concat(heroicon("arrow-top-right-on-square", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Open in New Tab")
      end
    end

    def share_button
      button_tag(
        type: "button",
        class: "inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors",
        data: { controller: "share-document", "share-document-id-value": document.id }
      ) do
        concat(heroicon("share", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Share")
      end
    end

    def edit_button
      link_to(
        edit_ged_document_path(document),
        class: "inline-flex items-center px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors"
      ) do
        concat(heroicon("pencil", variant: :solid, options: { class: "w-5 h-5 mr-2" }))
        concat("Edit")
      end
    end

    # URL helpers
    def preview_url(variant = :large)
      return asset_path('document-placeholder.png') unless document.file.attached?
      
      if document.respond_to?(:preview_url)
        document.preview_url(variant)
      elsif document.preview.attached?
        rails_blob_path(document.preview)
      elsif document.file.variable?
        rails_representation_path(document.file.variant(resize_to_limit: variant_dimensions(variant)))
      else
        rails_blob_path(document.file)
      end
    end

    def pdf_viewer_url
      # Can integrate PDF.js here for advanced features
      rails_blob_path(document.file)
    end

    def office_viewer_url
      # Microsoft Office Online Viewer URL
      # Format: https://view.officeapps.live.com/op/embed.aspx?src=URL_TO_DOCUMENT
      return nil unless document.publicly_accessible?
      
      "https://view.officeapps.live.com/op/embed.aspx?src=#{CGI.escape(document.public_url)}"
    end

    def load_text_content
      # Load text content with syntax highlighting if applicable
      content = document.file.download
      
      if document.code_file?
        # Apply syntax highlighting
        highlight_syntax(content, document.file_extension)
      else
        content.force_encoding('UTF-8').scrub('?')
      end
    rescue
      "Unable to load file content"
    end

    def archive_file_list
      # Would integrate with a service to list archive contents
      content_tag(:div, class: "text-sm text-gray-600") do
        "Archive preview coming soon..."
      end
    end

    def variant_dimensions(variant)
      case variant
      when :thumbnail then [200, 200]
      when :medium then [800, 600]
      when :large then [1200, 900]
      when :original then nil
      else [800, 600]
      end
    end

    def can_open_in_new_tab?
      document.pdf? || document.image? || document.text?
    end

    # Helper method delegations
    def policy(record)
      helpers.policy(record)
    end

    def heroicon(name, variant: :outline, options: {})
      helpers.heroicon(name, variant: variant, options: options)
    end

    def rails_blob_path(attachment)
      helpers.rails_blob_path(attachment)
    end

    def rails_representation_path(variant)
      helpers.rails_representation_path(variant)
    end

    def number_to_human_size(size)
      helpers.number_to_human_size(size)
    end

    def time_ago_in_words(time)
      helpers.time_ago_in_words(time)
    end

    def ged_download_document_path(doc)
      helpers.ged_download_document_path(doc)
    end

    def ged_document_path(doc)
      helpers.ged_document_path(doc)
    end

    def edit_ged_document_path(doc)
      helpers.ged_edit_document_path(doc)
    end
  end
end