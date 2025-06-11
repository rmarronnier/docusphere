module Immo
  module Promo
    class LotSpecification < ApplicationRecord
      self.table_name = 'immo_promo_lot_specifications'

      belongs_to :lot, class_name: 'Immo::Promo::Lot'
      
      # Enum pour la catégorie de lot
      enum category: {
        apartment: 'apartment',
        house: 'house',
        studio: 'studio',
        penthouse: 'penthouse',
        duplex: 'duplex',
        loft: 'loft',
        commercial: 'commercial',
        parking: 'parking',
        storage: 'storage'
      }

      def has_amenities?
        has_balcony || has_terrace || has_parking || has_storage
      end

      def total_rooms
        rooms || 0
      end
      
      # Alias pour compatibilité avec les tests
      def specification_type
        category
      end
      
      def specification_type=(value)
        self.category = value
      end
      
      # Méthode description basée sur les caractéristiques
      def description
        parts = []
        parts << "#{category&.humanize}" if category.present?
        parts << "#{rooms} pièces" if rooms.present?
        parts << "#{bedrooms} chambres" if bedrooms.present?
        parts << "#{bathrooms} salle(s) de bain" if bathrooms.present?
        
        amenities = []
        amenities << "balcon" if has_balcony?
        amenities << "terrasse" if has_terrace?
        amenities << "parking" if has_parking?
        amenities << "rangement" if has_storage?
        
        parts << "avec #{amenities.join(', ')}" if amenities.any?
        
        parts.join(', ')
      end
    end
  end
end
