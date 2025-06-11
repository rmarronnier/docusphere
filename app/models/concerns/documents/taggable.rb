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

    # Set tags from comma-separated string
    def tag_list=(names)
      self.tags = names.split(',').map(&:strip).uniq.map do |name|
        Tag.find_or_create_by(name: name, organization: space.organization)
      end
    end
  end
end