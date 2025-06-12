# frozen_string_literal: true

module Documents
  module Taggable
    extend ActiveSupport::Concern

    included do
      has_many :document_tags, dependent: :destroy
      has_many :tags, through: :document_tags
    end

    # Get tag list as comma-separated string
    def tag_list
      tags.pluck(:name).join(', ')
    end

    # Set tags from comma-separated string or array
    def tag_list=(names)
      # Handle both string and array inputs
      tag_names = case names
                  when String
                    names.split(',').map(&:strip)
                  when Array
                    names.map(&:strip)
                  else
                    []
                  end
      
      # Get organization from space, folder, or uploaded_by user
      organization = space&.organization || parent&.space&.organization || uploaded_by&.organization
      
      self.tags = tag_names.uniq.map do |name|
        Tag.find_or_create_by(name: name, organization: organization)
      end
    end
  end
end