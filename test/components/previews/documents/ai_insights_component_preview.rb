# @label AI Insights Component
class Documents::AiInsightsComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label AI Processed Document
  def ai_processed
    document = build_document_with_ai_data
    render Documents::AiInsightsComponent.new(document: document)
  end
  
  # @label Processing In Progress
  def processing
    document = build_document_processing
    render Documents::AiInsightsComponent.new(document: document)
  end
  
  # @label Not Supported
  def not_supported
    document = build_document_not_supported
    render Documents::AiInsightsComponent.new(document: document)
  end
  
  private
  
  def build_document_with_ai_data
    OpenStruct.new(
      ai_processed?: true,
      supports_ai_processing?: true,
      ai_classification_category: 'invoice',
      ai_classification_confidence_percent: 85,
      ai_entities: [
        {'type' => 'amount', 'value' => '1250.00 €'},
        {'type' => 'date', 'value' => '2024-06-15'},
        {'type' => 'organization', 'value' => 'ACME Corp'},
        {'type' => 'email', 'value' => 'contact@acme.com'}
      ],
      ai_entities_by_type: [
        {'type' => 'amount', 'value' => '1250.00 €'},
        {'type' => 'date', 'value' => '2024-06-15'},
        {'type' => 'organization', 'value' => 'ACME Corp'},
        {'type' => 'email', 'value' => 'contact@acme.com'}
      ],
      ai_summary: "Facture d'ACME Corp pour des services de consulting d'un montant de 1250€. La facture est datée du 15 juin 2024 et doit être réglée sous 30 jours.",
      extracted_text: "FACTURE N° 2024-0615\n\nACME Corp\n123 Rue de la République\n75001 Paris\n\nFACTURE À :\nClient Exemple\n456 Avenue des Exemples\n69000 Lyon\n\nDate: 15/06/2024\nÉchéance: 15/07/2024\n\nPRESTATIONS :\n- Consulting stratégique : 1250.00 €\n\nTOTAL HT : 1250.00 €\nTVA 20% : 250.00 €\nTOTAL TTC : 1500.00 €\n\nModalités de paiement :\nVirement bancaire sous 30 jours\nIBAN : FR76 1234 5678 9012 3456 78",
      ai_processed_at: Time.current
    )
  end
  
  def build_document_processing
    OpenStruct.new(
      ai_processed?: false,
      supports_ai_processing?: true
    )
  end
  
  def build_document_not_supported
    OpenStruct.new(
      ai_processed?: false,
      supports_ai_processing?: false
    )
  end
end