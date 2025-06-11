# frozen_string_literal: true

module Documents
  module Searchable
    extend ActiveSupport::Concern

    included do
      searchkick word_start: [:title, :description], 
                 searchable: [:title, :description, :content, :metadata_text],
                 filterable: [:document_type, :document_category, :documentable_type, :created_at, :user_id, :space_id, :tags]
    end

    # Search data for Elasticsearch
    def search_data
      {
        title: title,
        description: description,
        content: extracted_content,
        metadata_text: metadata_text,
        document_type: document_type,
        document_category: document_category,
        documentable_type: documentable_type,
        created_at: created_at,
        user_id: uploaded_by_id,
        space_id: space_id,
        tags: tags.pluck(:name)
      }
    end

    # Metadata text for search
    def metadata_text
      metadata.map { |m| "#{m.key}: #{m.value}" }.join(' ')
    end
  end
end