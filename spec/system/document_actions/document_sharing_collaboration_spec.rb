require 'rails_helper'

RSpec.describe 'Document Sharing and Collaboration Actions', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, first_name: 'Jean', last_name: 'Dupont', organization: organization) }
  let(:colleague) { create(:user, first_name: 'Marie', last_name: 'Martin', organization: organization) }
  let(:external_user) { create(:user, first_name: 'Pierre', last_name: 'External', email: 'external@client.com') }
  let(:folder) { create(:folder, name: 'Documents Partagés', space: create(:space, organization: organization)) }
  let(:document) { create(:document, title: 'Rapport Annuel 2025.pdf', folder: folder, space: folder.space, uploaded_by: user) }
  
  before do
    sign_in user
  end
  
  describe 'Internal Document Sharing' do
    it 'shares document with specific users' do
      visit ged_document_path(document)
      
      click_button 'Partager'
      
      within '.share-modal' do
        # Search and select user
        fill_in 'search_users', with: 'Marie'
        
        within '.user-search-results' do
          expect(page).to have_content('Marie Martin')
          click_button 'Ajouter'
        end
        
        within '.selected-users' do
          expect(page).to have_content('Marie Martin')
          
          # Set permissions
          within '.user-share-row', text: 'Marie Martin' do
            select 'Peut modifier', from: 'permission'
            check 'Peut partager'
            check 'Notifier par email'
          end
        end
        
        # Add message
        fill_in 'Message personnalisé', with: 'Voici le rapport annuel pour révision. Merci de vérifier les chiffres du Q4.'
        
        # Share options
        check 'Envoyer une copie du document'
        
        click_button 'Partager'
      end
      
      expect(page).to have_content('Document partagé avec 1 personne')
      
      # Check share indicator
      within '.document-header' do
        expect(page).to have_css('.share-indicator')
        expect(page).to have_content('Partagé avec 1 personne')
      end
      
      # Verify colleague access
      sign_out user
      sign_in colleague
      
      visit root_path
      
      within '.notifications' do
        expect(page).to have_content('Jean Dupont a partagé un document')
        click_link 'Rapport Annuel 2025.pdf'
      end
      
      expect(page).to have_content('Rapport Annuel 2025.pdf')
      expect(page).to have_button('Éditer')
      expect(page).to have_button('Partager')
    end
    
    it 'shares folder with user group' do
      group = create(:user_group, name: 'Équipe Finance', organization: organization)
      group.users << colleague
      
      visit ged_folder_path(folder)
      
      click_button 'Partager ce dossier'
      
      within '.share-modal' do
        click_tab 'Groupes'
        
        select 'Équipe Finance', from: 'group_select'
        click_button 'Ajouter groupe'
        
        within '.selected-groups' do
          expect(page).to have_content('Équipe Finance (5 membres)')
          
          select 'Lecture seule', from: 'group_permission'
          check 'Appliquer aux sous-dossiers'
          check 'Appliquer aux futurs documents'
        end
        
        click_button 'Partager'
      end
      
      expect(page).to have_content('Dossier partagé avec le groupe Équipe Finance')
      
      # Verify inherited permissions
      click_link document.name
      
      within '.permissions-info' do
        click_link 'Voir les permissions'
        
        expect(page).to have_content('Équipe Finance (hérité du dossier)')
        expect(page).to have_content('Lecture seule')
      end
    end
  end
  
  describe 'External Document Sharing' do
    it 'creates secure external share link' do
      visit ged_document_path(document)
      
      click_button 'Partager'
      click_tab 'Lien externe'
      
      within '.external-share-tab' do
        # Security settings
        check 'Activer le partage externe'
        select 'Lecture seule', from: 'access_level'
        check 'Exiger une authentification'
        check 'Limiter dans le temps'
        fill_in 'Expire le', with: 30.days.from_now.to_date
        check 'Protéger par mot de passe'
        fill_in 'Mot de passe', with: 'SecurePass2025!'
        
        # Tracking
        check 'Suivre les accès'
        check 'Filigrane avec email du lecteur'
        
        # Generate link
        click_button 'Générer le lien'
      end
      
      within '.share-link-generated' do
        expect(page).to have_content('Lien sécurisé créé')
        expect(page).to have_css('.share-link')
        expect(page).to have_button('Copier')
        expect(page).to have_button('Envoyer par email')
        expect(page).to have_button('QR Code')
        
        # Copy link
        click_button 'Copier'
        expect(page).to have_content('Lien copié')
        
        # Send by email
        click_button 'Envoyer par email'
      end
      
      within '.email-share-modal' do
        fill_in 'Destinataires', with: 'external@client.com, partner@company.com'
        fill_in 'Objet', with: 'Document confidentiel - Rapport Annuel 2025'
        fill_in 'Message', with: 'Veuillez trouver ci-joint le lien sécurisé vers notre rapport annuel.'
        
        check 'Inclure les instructions d\'accès'
        check 'M\'envoyer une copie'
        
        click_button 'Envoyer'
      end
      
      expect(page).to have_content('Email envoyé à 2 destinataires')
      
      # Check share tracking
      click_link 'Voir les accès'
      
      within '.share-tracking-modal' do
        expect(page).to have_content('Lien créé il y a moins d\'une minute')
        expect(page).to have_content('Expire dans 30 jours')
        expect(page).to have_content('0 consultations')
        expect(page).to have_content('Email envoyé à 2 personnes')
      end
    end
    
    it 'manages guest access with watermark' do
      # Create public share
      share_link = create(:document_share, 
        document: document,
        share_type: 'link',
        access_level: 'view',
        requires_auth: false,
        add_watermark: true
      )
      
      # Logout and access as guest
      sign_out user
      
      visit share_link.public_url
      
      # Guest access page
      expect(page).to have_content('Accès invité')
      expect(page).to have_content('Rapport Annuel 2025.pdf')
      
      fill_in 'Votre email', with: 'guest@example.com'
      fill_in 'Votre nom', with: 'Guest User'
      check 'J\'accepte les conditions d\'utilisation'
      
      click_button 'Accéder au document'
      
      # Document viewer with restrictions
      expect(page).to have_css('.guest-document-viewer')
      expect(page).to have_css('.watermark-overlay')
      expect(page).to have_content('guest@example.com') # Watermark
      
      # Restricted actions
      expect(page).not_to have_button('Télécharger')
      expect(page).not_to have_button('Imprimer')
      expect(page).to have_css('.download-disabled')
      expect(page).to have_css('.print-disabled')
      
      # Context menu disabled
      page.find('.document-content').right_click
      expect(page).not_to have_css('.context-menu')
    end
  end
  
  describe 'Real-time Collaboration' do
    it 'shows real-time presence indicators' do
      # User opens document
      visit ged_document_path(document)
      
      expect(page).to have_css('.presence-indicator')
      expect(page).to have_content('Vous consultez ce document')
      
      # Colleague opens same document in another session
      using_session :colleague do
        sign_in colleague
        visit ged_document_path(document)
        
        expect(page).to have_css('.presence-indicator')
        expect(page).to have_content('Jean Dupont consulte également')
        expect(page).to have_css('.user-avatar', text: 'JD')
      end
      
      # Back to first user - sees colleague
      expect(page).to have_content('Marie Martin consulte également')
      expect(page).to have_css('.user-avatar', text: 'MM')
      
      # Real-time cursor tracking (for compatible formats)
      within '.collaborative-features' do
        expect(page).to have_css('.active-users-list')
        expect(page).to have_content('2 personnes actives')
      end
    end
    
    it 'enables collaborative annotations' do
      visit ged_document_path(document)
      
      # Enable annotation mode
      click_button 'Annoter'
      
      expect(page).to have_css('.annotation-toolbar')
      
      within '.annotation-toolbar' do
        click_button 'Commentaire'
      end
      
      # Click on document to place annotation
      page.find('.document-page').click
      
      within '.annotation-popup' do
        fill_in 'Commentaire', with: 'Vérifier ces chiffres avec la compta'
        select 'Question', from: 'Type'
        check 'Mentionner un collègue'
        select 'Marie Martin', from: 'mention'
        
        click_button 'Ajouter'
      end
      
      expect(page).to have_css('.annotation-marker')
      expect(page).to have_content('1 annotation')
      
      # Colleague receives notification and responds
      using_session :colleague do
        sign_in colleague
        visit root_path
        
        within '.notifications' do
          expect(page).to have_content('Jean Dupont vous a mentionné')
          click_link 'dans une annotation'
        end
        
        # Document opens with annotation highlighted
        expect(page).to have_css('.annotation-marker.highlighted')
        
        click_on '.annotation-marker'
        
        within '.annotation-thread' do
          expect(page).to have_content('Vérifier ces chiffres avec la compta')
          expect(page).to have_content('@Marie Martin')
          
          fill_in 'Répondre', with: 'Les chiffres sont corrects, validés ce matin'
          click_button 'Répondre'
        end
      end
      
      # Original user sees response in real-time
      within '.annotation-thread' do
        expect(page).to have_content('Les chiffres sont corrects')
        expect(page).to have_content('Marie Martin')
        
        # Resolve annotation
        click_button 'Marquer comme résolu'
      end
      
      expect(page).to have_css('.annotation-marker.resolved')
    end
  end
  
  describe 'Document Share Management' do
    let!(:active_shares) do
      [
        create(:document_share, document: document, shared_with: colleague, access_level: 'edit'),
        create(:document_share, document: document, share_type: 'link', expires_at: 7.days.from_now)
      ]
    end
    
    it 'manages active document shares' do
      visit ged_document_path(document)
      
      click_link 'Gérer les partages'
      
      within '.share-management-modal' do
        expect(page).to have_content('Partages actifs')
        
        # User shares
        within '.user-shares' do
          expect(page).to have_content('Marie Martin')
          expect(page).to have_content('Peut modifier')
          
          within ".share-row[data-id='#{active_shares[0].id}']" do
            # Change permission
            select 'Lecture seule', from: 'permission'
            
            expect(page).to have_content('Permissions mises à jour')
            
            # Revoke share
            click_button 'Révoquer'
          end
          
          accept_confirm
          
          expect(page).not_to have_content('Marie Martin')
        end
        
        # Link shares
        within '.link-shares' do
          expect(page).to have_content('Lien externe')
          expect(page).to have_content('Expire dans 7 jours')
          expect(page).to have_content('0 consultations')
          
          # Extend expiration
          within ".share-row[data-id='#{active_shares[1].id}']" do
            click_button 'Prolonger'
            
            fill_in 'Nouvelle date', with: 30.days.from_now.to_date
            click_button 'Mettre à jour'
          end
          
          expect(page).to have_content('Expire dans 30 jours')
          
          # View access logs
          click_button 'Voir les accès'
        end
      end
      
      within '.access-logs-modal' do
        expect(page).to have_content('Journal des accès')
        expect(page).to have_css('.access-log-table')
        
        # Would show actual access logs if any
        expect(page).to have_content('Aucun accès enregistré')
      end
    end
    
    it 'bulk shares multiple documents' do
      documents = create_list(:document, 3, folder: folder)
      
      visit ged_folder_path(folder)
      
      # Select documents
      documents.each { |doc| check "select_#{doc.id}" }
      
      within '.bulk-actions-bar' do
        click_button 'Partager'
      end
      
      within '.bulk-share-modal' do
        expect(page).to have_content('Partager 3 documents')
        
        # Add recipients
        fill_in 'emails', with: 'team@company.com, partner@external.com'
        
        # Settings for all
        select 'Lecture seule', from: 'permission'
        check 'Envoyer une notification'
        check 'Créer un dossier partagé'
        fill_in 'Nom du dossier', with: 'Documents Projet Q4'
        
        # Expiration
        check 'Définir une expiration'
        fill_in 'expire_date', with: 90.days.from_now.to_date
        
        click_button 'Partager tous'
      end
      
      expect(page).to have_content('3 documents partagés avec succès')
      expect(page).to have_content('Dossier partagé créé: Documents Projet Q4')
      
      # Check shared folder
      visit shared_folders_path
      
      expect(page).to have_content('Documents Projet Q4')
      expect(page).to have_content('3 documents')
      expect(page).to have_content('Partagé avec 2 personnes')
    end
  end
  
  describe 'Collaborative Workflows' do
    it 'initiates document review workflow' do
      visit ged_document_path(document)
      
      click_button 'Démarrer un workflow'
      select 'Révision collaborative', from: 'workflow_type'
      
      within '.workflow-setup-modal' do
        # Step 1: Add reviewers
        within '.step-reviewers' do
          fill_in 'search_reviewers', with: 'Mar'
          click_button 'Ajouter Marie Martin'
          
          fill_in 'search_reviewers', with: 'Pier'
          click_button 'Ajouter Pierre External'
          
          # Set order
          select 'Parallèle', from: 'review_order'
          
          # Set deadline
          fill_in 'deadline', with: 5.days.from_now.to_date
        end
        
        click_button 'Suivant'
        
        # Step 2: Instructions
        within '.step-instructions' do
          fill_in 'Instructions générales', with: 'Merci de réviser ce rapport et de valider les sections qui vous concernent.'
          
          # Specific instructions
          within '.reviewer-instructions' do
            fill_in 'instructions_marie', with: 'Focus sur les aspects financiers'
            fill_in 'instructions_pierre', with: 'Validation technique requise'
          end
        end
        
        click_button 'Suivant'
        
        # Step 3: Confirmation
        within '.step-confirmation' do
          expect(page).to have_content('2 réviseurs')
          expect(page).to have_content('Révision parallèle')
          expect(page).to have_content('Échéance: 5 jours')
          
          check 'Envoyer les notifications immédiatement'
          check 'Me notifier à chaque étape'
          
          click_button 'Lancer le workflow'
        end
      end
      
      expect(page).to have_content('Workflow de révision démarré')
      
      within '.document-header' do
        expect(page).to have_css('.workflow-badge')
        expect(page).to have_content('En révision (0/2)')
      end
      
      # Check workflow status
      click_link 'Voir le statut du workflow'
      
      within '.workflow-status-modal' do
        expect(page).to have_css('.workflow-timeline')
        
        within '.reviewer-status' do
          expect(page).to have_content('Marie Martin - En attente')
          expect(page).to have_content('Pierre External - En attente')
        end
        
        expect(page).to have_content('Temps restant: 5 jours')
        
        # Send reminder
        within ".reviewer-row[data-reviewer='marie']" do
          click_button 'Envoyer un rappel'
        end
        
        expect(page).to have_content('Rappel envoyé')
      end
    end
    
    it 'completes approval workflow with electronic signatures' do
      approval_request = create(:validation_request,
        document: document,
        requested_by: user,
        validator: colleague,
        status: 'pending'
      )
      
      # Approver signs in
      sign_out user
      sign_in colleague
      
      visit validation_request_path(approval_request)
      
      expect(page).to have_content('Demande d\'approbation')
      expect(page).to have_content('Rapport Annuel 2025.pdf')
      
      # Review document
      click_button 'Examiner le document'
      
      # Document opens in viewer
      expect(page).to have_css('.document-viewer')
      
      # Add approval signature
      click_button 'Approuver et signer'
      
      within '.signature-modal' do
        # Draw signature
        canvas = find('#signature-pad')
        
        # Simulate drawing
        page.execute_script(<<~JS
          const canvas = document.querySelector('#signature-pad');
          const ctx = canvas.getContext('2d');
          ctx.beginPath();
          ctx.moveTo(50, 50);
          ctx.lineTo(150, 50);
          ctx.stroke();
        JS
        )
        
        fill_in 'Commentaire', with: 'Document approuvé sans réserve'
        
        check 'J\'atteste avoir lu et approuvé ce document'
        
        click_button 'Signer et approuver'
      end
      
      expect(page).to have_content('Document approuvé et signé')
      
      # Certificate generated
      within '.signature-confirmation' do
        expect(page).to have_content('Certificat de signature')
        expect(page).to have_content("Signé par: #{colleague.name}")
        expect(page).to have_content("Date: #{I18n.l(Date.current)}")
        expect(page).to have_button('Télécharger le certificat')
      end
      
      # Original user sees approval
      sign_out colleague
      sign_in user
      
      visit ged_document_path(document)
      
      within '.document-approvals' do
        expect(page).to have_css('.approval-badge')
        expect(page).to have_content("Approuvé par #{colleague.name}")
        expect(page).to have_css('.signature-verified')
      end
    end
  end
end