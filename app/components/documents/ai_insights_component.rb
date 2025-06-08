class Documents::AiInsightsComponent < ApplicationComponent
  def initialize(document:)
    @document = document
  end

  private

  attr_reader :document

  def show_ai_insights?
    document.ai_processed?
  end

  def classification_badge_color
    case document.ai_classification_confidence_percent
    when 80..100
      'bg-green-100 text-green-800'
    when 60...80
      'bg-yellow-100 text-yellow-800'
    when 40...60
      'bg-orange-100 text-orange-800'
    else
      'bg-red-100 text-red-800'
    end
  end

  def confidence_level_text
    case document.ai_classification_confidence_percent
    when 80..100
      'Très fiable'
    when 60...80
      'Fiable'
    when 40...60
      'Modérée'
    else
      'Faible'
    end
  end

  def entity_icon(entity_type)
    icons = {
      'email' => 'M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z',
      'phone' => 'M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z',
      'date' => 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z',
      'amount' => 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1',
      'person' => 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
      'organization' => 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4',
      'location' => 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z',
      'siret' => 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'
    }
    
    icons[entity_type] || icons['organization']
  end

  def entity_color(entity_type)
    colors = {
      'email' => 'text-blue-600',
      'phone' => 'text-green-600',
      'date' => 'text-purple-600',
      'amount' => 'text-yellow-600',
      'person' => 'text-indigo-600',
      'organization' => 'text-red-600',
      'location' => 'text-gray-600',
      'siret' => 'text-pink-600'
    }
    
    colors[entity_type] || 'text-gray-600'
  end

  def category_description(category)
    descriptions = {
      'invoice' => 'Document de facturation',
      'contract' => 'Contrat ou accord',
      'report' => 'Rapport ou étude',
      'letter' => 'Courrier officiel',
      'form' => 'Formulaire administratif',
      'technical_doc' => 'Documentation technique',
      'legal_doc' => 'Document juridique',
      'financial_doc' => 'Document financier'
    }
    
    descriptions[category] || 'Type de document'
  end
end