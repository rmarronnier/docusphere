class Immo::Promo::ProjectCard::HeaderComponent < ApplicationComponent
  def initialize(project:, show_thumbnail: true, variant: :default)
    @project = project
    @show_thumbnail = show_thumbnail
    @variant = variant
  end

  private

  attr_reader :project, :show_thumbnail, :variant

  def project_path
    ImmoPromo::Engine.routes.url_helpers.project_path(project)
  end

  def has_thumbnail?
    return false unless show_thumbnail
    return false unless project.respond_to?(:technical_documents)
    
    # Handle both actual Active Storage attachments and test mocks
    technical_docs = project.technical_documents
    if technical_docs.respond_to?(:attached?)
      technical_docs.attached?
    elsif technical_docs.respond_to?(:any?)
      technical_docs.any?
    else
      false
    end
  end

  def thumbnail_url
    return nil unless has_thumbnail?
    
    # Find the first image attachment
    image_attachment = project.technical_documents.find { |doc| doc.content_type.start_with?('image/') }
    return nil unless image_attachment
    
    # Return a variant URL if possible
    begin
      Rails.application.routes.url_helpers.rails_blob_path(image_attachment.variant(resize_to_limit: [200, 150]), only_path: true)
    rescue
      Rails.application.routes.url_helpers.rails_blob_path(image_attachment, only_path: true)
    end
  end

  def project_icon
    case project.project_type
    when 'residential'
      :home
    when 'commercial', 'retail'
      :office_building
    when 'mixed'
      :building_office_2
    when 'industrial'
      :building_storefront
    else
      :office_building
    end
  end

  def compact_layout?
    variant == :compact
  end
end