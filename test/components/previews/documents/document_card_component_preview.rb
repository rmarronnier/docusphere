# @label Document Card Component
class Documents::DocumentCardComponentPreview < Lookbook::Preview
  layout "application"
  
  # @label Default Document Card
  def default
    document = OpenStruct.new(
      title: "Rapport Mensuel Mars 2024",
      file_type: "PDF",
      file_size: "2.4 MB",
      created_at: 2.days.ago,
      updated_at: 1.day.ago,
      status: "published",
      tags: ["rapport", "mensuel", "mars"],
      uploaded_by: OpenStruct.new(name: "Jean Dupont")
    )
    
    render Documents::DocumentCardComponent.new(document: document)
  end
  
  # @label Different Document Types
  def different_types
    documents = [
      OpenStruct.new(
        title: "Présentation Projet Alpha",
        file_type: "PPTX",
        file_size: "5.2 MB",
        created_at: 3.days.ago,
        updated_at: 1.day.ago,
        status: "draft",
        tags: ["présentation", "projet"],
        uploaded_by: OpenStruct.new(name: "Marie Martin")
      ),
      OpenStruct.new(
        title: "Budget Prévisionnel 2024",
        file_type: "XLSX",
        file_size: "1.8 MB",
        created_at: 1.week.ago,
        updated_at: 2.days.ago,
        status: "published",
        tags: ["budget", "2024", "prévisions"],
        uploaded_by: OpenStruct.new(name: "Pierre Bernard")
      ),
      OpenStruct.new(
        title: "Contrat Client XYZ",
        file_type: "DOCX",
        file_size: "340 KB",
        created_at: 5.days.ago,
        updated_at: 3.days.ago,
        status: "pending",
        tags: ["contrat", "client", "xyz"],
        uploaded_by: OpenStruct.new(name: "Claire Dubois")
      ),
      OpenStruct.new(
        title: "Photo Site Construction",
        file_type: "JPG",
        file_size: "4.7 MB",
        created_at: 2.hours.ago,
        updated_at: 2.hours.ago,
        status: "published",
        tags: ["photo", "site", "construction"],
        uploaded_by: OpenStruct.new(name: "David Moreau")
      )
    ]
    
    content_tag :div, class: "grid grid-cols-2 gap-4" do
      documents.map { |doc| render(Documents::DocumentCardComponent.new(document: doc)) }.join.html_safe
    end
  end
  
  # @label Document States
  def document_states
    states = [
      { status: "published", title: "Document Publié", tags: ["publié", "actif"] },
      { status: "draft", title: "Document Brouillon", tags: ["brouillon", "en cours"] },
      { status: "pending", title: "En Attente de Validation", tags: ["validation", "attente"] },
      { status: "archived", title: "Document Archivé", tags: ["archivé", "ancien"] },
      { status: "error", title: "Erreur de Traitement", tags: ["erreur", "problème"] }
    ]
    
    content_tag :div, class: "grid grid-cols-1 gap-4" do
      states.map do |state|
        document = OpenStruct.new(
          title: state[:title],
          file_type: "PDF",
          file_size: "1.2 MB",
          created_at: 1.day.ago,
          updated_at: 1.hour.ago,
          status: state[:status],
          tags: state[:tags],
          uploaded_by: OpenStruct.new(name: "Utilisateur Test")
        )
        render(Documents::DocumentCardComponent.new(document: document))
      end.join.html_safe
    end
  end
  
  # @label With Actions
  def with_actions
    document = OpenStruct.new(
      title: "Contrat Important",
      file_type: "PDF",
      file_size: "890 KB",
      created_at: 1.day.ago,
      updated_at: 2.hours.ago,
      status: "published",
      tags: ["contrat", "important", "signature"],
      uploaded_by: OpenStruct.new(name: "Manager Projet")
    )
    
    render Documents::DocumentCardComponent.new(document: document, show_actions: true) do |card|
      card.with_action(text: "Télécharger", href: "#", icon: "download", variant: "primary")
      card.with_action(text: "Partager", href: "#", icon: "share", variant: "secondary")
      card.with_action(text: "Modifier", href: "#", icon: "edit", variant: "outline")
    end
  end
  
  # @label Compact Layout
  def compact
    documents = [
      OpenStruct.new(
        title: "Note Réunion 15/03",
        file_type: "DOCX",
        file_size: "125 KB",
        created_at: 1.hour.ago,
        status: "published",
        uploaded_by: OpenStruct.new(name: "Secrétaire")
      ),
      OpenStruct.new(
        title: "Facture #001234",
        file_type: "PDF",
        file_size: "78 KB",
        created_at: 3.hours.ago,
        status: "published",
        uploaded_by: OpenStruct.new(name: "Comptabilité")
      ),
      OpenStruct.new(
        title: "Plan Technique v2.1",
        file_type: "DWG",
        file_size: "12.4 MB",
        created_at: 2.days.ago,
        status: "draft",
        uploaded_by: OpenStruct.new(name: "Architecte")
      )
    ]
    
    content_tag :div, class: "space-y-2" do
      documents.map { |doc| render(Documents::DocumentCardComponent.new(document: doc, layout: "compact")) }.join.html_safe
    end
  end
end