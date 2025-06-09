module Immo
  module Promo
    class LotSpecification < ApplicationRecord
      self.table_name = 'immo_promo_lot_specifications'

      belongs_to :lot, class_name: 'Immo::Promo::Lot'

      def has_amenities?
        has_balcony || has_terrace || has_parking || has_storage
      end

      def total_rooms
        rooms || 0
      end
    end
  end
end
