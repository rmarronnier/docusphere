class EmailUploadJob < ApplicationJob
  queue_as :default

  def perform(to:, from:, subject:, attachments:)
    # Extraire le code unique de l'adresse email
    if to =~ /upload\+([A-Z0-9]+)@/
      unique_code = $1
      
      # Trouver l'utilisateur et l'espace/dossier associé au code
      # Pour la démo, on simule la création des documents
      user = User.find_by(email: from)
      
      if user
        organization = user.organization
        space = organization.spaces.first || organization.spaces.create!(name: 'Espace Principal')
        folder = space.folders.first || space.folders.create!(name: 'Documents Email', organization: organization)
        
        attachments.each do |attachment_name|
          # Créer un document pour chaque pièce jointe
          document = Document.new(
            title: attachment_name,
            folder: folder,
            space: space,
            uploaded_by: user,
            description: "Reçu par email: #{subject}",
            skip_file_validation: true
          )
          document.save!
        end
        
        # Créer une notification pour l'utilisateur
        Notification.create!(
          user: user,
          title: 'Documents reçus par email',
          message: "#{attachments.size} nouveaux documents reçus par email",
          notification_type: 'document_shared',
          data: {
            attachment_count: attachments.size,
            subject: subject
          }
        )
      end
    end
  end
end