class DocumentShare < ApplicationRecord
  belongs_to :document
  belongs_to :user
  belongs_to :shared_by
end
