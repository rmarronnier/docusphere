require 'rails_helper'

RSpec.describe 'Document Workflow and Automation Actions', type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:manager) { create(:user, name: 'Manager User', organization: organization) }
  let(:validator) { create(:user, name: 'Validator User', organization: organization) }
  let(:folder) { create(:folder, organization: organization) }
  
  before do
    manager.add_role(:manager)
    validator.add_role(:validator)
    sign_in user
  end
  
  describe 'Document Validation Workflow' do
    let(:document) { create(:document, :with_pdf_file, title: 'Contract_Draft.pdf', folder: folder, uploaded_by: user) }
    
    it 'initiates validation workflow' do
      visit ged_document_path(document)
      
      click_button 'Demander validation'
      
      within '.validation-request-modal' do
        # Select validator
        select 'Validator User', from: 'Validateur'
        
        # Priority and deadline
        select 'Haute', from: 'Priorité'
        fill_in 'Date limite', with: 3.days.from_now.to_date
        
        # Context
        fill_in 'Message', with: 'Merci de valider ce contrat avant signature. Points d\'attention: clauses 3.2 et 5.1'
        
        # Validation type
        select 'Validation juridique', from: 'Type de validation'
        
        # Options
        check 'Bloquer les modifications pendant la validation'
        check 'Notifier par email'
        check 'Rappel automatique 24h avant échéance'
        
        click_button 'Envoyer la demande'
      end
      
      expect(page).to have_content('Demande de validation envoyée')
      expect(page).to have_css('.validation-pending-badge')
      expect(page).to have_content('En attente de validation')
      expect(page).not_to have_button('Éditer') # Document locked
      
      # Check validation request created
      visit ged_my_validation_requests_path
      
      expect(page).to have_content('Mes demandes de validation')
      
      within '.validation-request-sent' do
        expect(page).to have_content('Contract_Draft.pdf')
        expect(page).to have_content('Validator User')
        expect(page).to have_content('En attente')
        expect(page).to have_css('.priority-high')
      end
    end
    
    it 'processes validation as validator' do
      validation_request = create(:validation_request,
        document: document,
        requested_by: user,
        validator: validator,
        priority: 'high',
        message: 'Please review sections 3 and 5'
      )
      
      sign_out user
      sign_in validator
      
      visit root_path
      
      # Notification
      within '.notifications' do
        expect(page).to have_content('Nouvelle demande de validation')
        click_link 'Contract_Draft.pdf'
      end
      
      expect(current_path).to eq(validation_request_path(validation_request))
      
      # Review interface
      expect(page).to have_content('Demande de validation')
      expect(page).to have_content('Please review sections 3 and 5')
      
      # Open document
      click_button 'Examiner le document'
      
      # In document viewer with validation tools
      expect(page).to have_css('.validation-toolbar')
      
      within '.validation-toolbar' do
        click_button 'Annoter'
      end
      
      # Add validation comments
      page.find('.document-page').click
      
      within '.annotation-form' do
        fill_in 'Commentaire', with: 'Clause 3.2 needs clarification on payment terms'
        select 'Correction requise', from: 'Type'
        click_button 'Ajouter'
      end
      
      # Make decision
      click_button 'Prendre une décision'
      
      within '.validation-decision-modal' do
        choose 'Approuver avec réserves'
        
        fill_in 'Commentaire général', with: 'Document approuvé sous réserve des modifications demandées sur la clause 3.2'
        
        # Conditions
        check 'Modifications requises'
        fill_in 'Liste des modifications', with: '- Clarifier les termes de paiement (clause 3.2)\n- Ajouter date de début de contrat'
        
        click_button 'Valider'
      end
      
      expect(page).to have_content('Validation enregistrée')
      expect(page).to have_content('Approuvé avec réserves')
      
      # Original user receives notification
      sign_out validator
      sign_in user
      
      visit root_path
      
      within '.notifications' do
        expect(page).to have_content('Document validé avec réserves')
        click_link 'Voir les détails'
      end
      
      expect(page).to have_content('Modifications requises')
      expect(page).to have_content('Clarifier les termes de paiement')
    end
  end
  
  describe 'Automated Document Processing' do
    it 'triggers automatic workflows on upload' do
      visit ged_folder_path(folder)
      
      click_button 'Téléverser un document'
      
      within '.upload-modal' do
        attach_file 'document[file]', Rails.root.join('spec/fixtures/files/invoice_scan.pdf')
        
        # Automatic processing options
        check 'Traitement automatique'
        
        within '.auto-processing-options' do
          check 'Extraction de données (OCR)'
          check 'Classification automatique'
          check 'Détection de doublons'
          check 'Génération de vignettes'
        end
        
        click_button 'Téléverser'
      end
      
      expect(page).to have_content('Document en cours de traitement...')
      
      # Processing status
      within '.document-card', text: 'invoice_scan.pdf' do
        expect(page).to have_css('.processing-status')
        expect(page).to have_content('4 tâches en cours')
        
        click_link 'Voir le statut'
      end
      
      within '.processing-status-modal' do
        expect(page).to have_content('Traitement en cours')
        
        # Task progress
        expect(page).to have_css('.task-progress', count: 4)
        expect(page).to have_content('OCR - En cours')
        expect(page).to have_content('Classification - En attente')
        expect(page).to have_content('Détection doublons - En attente')
        expect(page).to have_content('Vignettes - Terminé')
        
        # Wait for completion (in test, it's fast)
        sleep 2
        click_button 'Actualiser'
        
        expect(page).to have_content('OCR - Terminé')
        expect(page).to have_content('Classification - Terminé')
      end
      
      # Check results
      visit ged_document_path(Document.last)
      
      within '.document-metadata' do
        expect(page).to have_content('Type: Facture') # Auto-classified
        expect(page).to have_content('Montant: 1,250.00€') # OCR extracted
        expect(page).to have_content('Date: 15/12/2025') # OCR extracted
        expect(page).to have_content('Fournisseur: ACME Corp') # OCR extracted
      end
      
      within '.processing-alerts' do
        expect(page).to have_content('Aucun doublon détecté')
      end
    end
    
    it 'configures folder automation rules' do
      sign_in manager
      visit ged_folder_path(folder)
      
      click_button 'Paramètres du dossier'
      click_tab 'Automatisation'
      
      within '.folder-automation' do
        click_button 'Nouvelle règle'
        
        within '.rule-builder' do
          # Condition
          select 'Type de fichier', from: 'condition_type'
          select 'est', from: 'condition_operator'
          select 'PDF', from: 'condition_value'
          
          click_button 'ET'
          
          select 'Nom contient', from: 'condition_type_2'
          fill_in 'condition_value_2', with: 'facture'
          
          # Actions
          within '.rule-actions' do
            click_button 'Ajouter une action'
            
            select 'Déplacer vers', from: 'action_type_1'
            select 'Comptabilité/Factures', from: 'action_target_1'
            
            click_button 'Ajouter une action'
            
            select 'Ajouter tag', from: 'action_type_2'
            fill_in 'action_value_2', with: 'facture-auto'
            
            click_button 'Ajouter une action'
            
            select 'Notifier', from: 'action_type_3'
            select 'Service Comptabilité', from: 'action_target_3'
          end
          
          # Rule settings
          fill_in 'Nom de la règle', with: 'Traitement automatique factures'
          check 'Règle active'
          
          click_button 'Créer la règle'
        end
      end
      
      expect(page).to have_content('Règle d\'automatisation créée')
      
      # Test rule
      visit ged_folder_path(folder)
      
      # Upload matching document
      click_button 'Téléverser un document'
      attach_file 'document[file]', Rails.root.join('spec/fixtures/files/facture_test.pdf')
      click_button 'Téléverser'
      
      expect(page).to have_content('Règle d\'automatisation appliquée')
      expect(page).not_to have_content('facture_test.pdf') # Moved to other folder
      
      # Check target folder
      visit ged_folder_path(Folder.find_by(name: 'Factures'))
      
      expect(page).to have_content('facture_test.pdf')
      
      within '.document-card', text: 'facture_test.pdf' do
        expect(page).to have_css('.tag', text: 'facture-auto')
      end
    end
  end
  
  describe 'Document Lifecycle Automation' do
    it 'configures retention policies' do
      sign_in manager
      visit document_policies_path
      
      click_button 'Nouvelle politique'
      
      within '.retention-policy-form' do
        fill_in 'Nom', with: 'Rétention documents financiers'
        
        # Scope
        within '.policy-scope' do
          select 'Catégorie', from: 'scope_type'
          select 'Documents financiers', from: 'scope_value'
        end
        
        # Retention period
        fill_in 'Durée de conservation', with: '7'
        select 'Années', from: 'retention_unit'
        
        # Actions after retention
        select 'Archiver', from: 'post_retention_action'
        check 'Compresser avant archivage'
        check 'Notifier le propriétaire'
        
        # Exceptions
        click_button 'Ajouter une exception'
        
        within '.exception-rule' do
          select 'Tag contient', from: 'exception_type'
          fill_in 'exception_value', with: 'conservation-permanente'
        end
        
        click_button 'Créer politique'
      end
      
      expect(page).to have_content('Politique de rétention créée')
      
      # View applied policies
      document = create(:document, category: 'financial', created_at: 8.years.ago)
      
      visit ged_document_path(document)
      
      within '.document-lifecycle' do
        expect(page).to have_content('Politique de rétention')
        expect(page).to have_content('Archivage prévu dans: 30 jours')
        expect(page).to have_css('.retention-warning')
      end
    end
    
    it 'sets up approval chains' do
      sign_in manager
      visit workflow_templates_path
      
      click_button 'Nouveau workflow'
      
      within '.workflow-builder' do
        fill_in 'Nom du workflow', with: 'Approbation contrats > 50k€'
        
        # Trigger
        within '.workflow-trigger' do
          select 'Upload de document', from: 'trigger_type'
          
          # Conditions
          click_button 'Ajouter condition'
          select 'Catégorie', from: 'condition_field'
          select 'est', from: 'condition_operator'
          select 'Contrat', from: 'condition_value'
          
          click_button 'ET'
          select 'Montant', from: 'condition_field_2'
          select 'supérieur à', from: 'condition_operator_2'
          fill_in 'condition_value_2', with: '50000'
        end
        
        # Steps
        within '.workflow-steps' do
          # Step 1
          click_button 'Ajouter étape'
          
          within '.step-1' do
            fill_in 'Nom étape', with: 'Validation juridique'
            select 'Validation', from: 'step_type'
            select 'Service Juridique', from: 'assignee'
            fill_in 'Délai', with: '2'
            select 'Jours ouvrés', from: 'delay_unit'
          end
          
          # Step 2
          click_button 'Ajouter étape'
          
          within '.step-2' do
            fill_in 'Nom étape', with: 'Approbation Direction'
            select 'Approbation', from: 'step_type'
            select 'Direction', from: 'assignee'
            fill_in 'Délai', with: '1'
            select 'Jours ouvrés', from: 'delay_unit'
            check 'Étape finale'
          end
        end
        
        # Notifications
        within '.workflow-notifications' do
          check 'Notifier à chaque étape'
          check 'Rappel automatique avant échéance'
          check 'Escalade si retard'
        end
        
        click_button 'Créer workflow'
      end
      
      expect(page).to have_content('Workflow créé avec succès')
      
      # Test workflow
      visit ged_folder_path(folder)
      
      # Upload contract > 50k
      click_button 'Téléverser un document'
      attach_file 'document[file]', Rails.root.join('spec/fixtures/files/big_contract.pdf')
      select 'Contrat', from: 'Catégorie'
      fill_in 'Montant', with: '75000'
      click_button 'Téléverser'
      
      expect(page).to have_content('Workflow déclenché: Approbation contrats > 50k€')
      
      within '.document-card' do
        expect(page).to have_css('.workflow-badge')
        expect(page).to have_content('Étape 1/2: Validation juridique')
      end
    end
  end
  
  describe 'Batch Processing Workflows' do
    let!(:documents) { create_list(:document, 5, folder: folder, status: 'draft') }
    
    it 'applies workflow to multiple documents' do
      visit ged_folder_path(folder)
      
      # Select documents
      check 'select_all'
      
      within '.bulk-actions-bar' do
        click_button 'Workflow'
        click_link 'Appliquer workflow'
      end
      
      within '.batch-workflow-modal' do
        select 'Validation standard', from: 'workflow_template'
        
        # Preview affected documents
        expect(page).to have_content('5 documents sélectionnés')
        
        within '.documents-preview' do
          documents.each do |doc|
            expect(page).to have_content(doc.name)
          end
        end
        
        # Workflow parameters
        select 'Manager User', from: 'validator'
        fill_in 'deadline', with: 5.days.from_now
        fill_in 'batch_message', with: 'Validation groupée des documents Q4'
        
        # Options
        check 'Traiter en parallèle'
        check 'Grouper les notifications'
        
        click_button 'Lancer le workflow'
      end
      
      expect(page).to have_content('Workflow appliqué à 5 documents')
      
      # Check batch status
      visit batch_workflows_path
      
      within '.batch-workflow-item' do
        expect(page).to have_content('Validation groupée')
        expect(page).to have_content('5 documents')
        expect(page).to have_content('En cours')
        expect(page).to have_css('.progress-bar')
        
        click_link 'Voir détails'
      end
      
      within '.batch-details' do
        expect(page).to have_content('0/5 complétés')
        
        # Document statuses
        documents.each do |doc|
          within "#batch_doc_#{doc.id}" do
            expect(page).to have_content(doc.name)
            expect(page).to have_content('En attente')
          end
        end
      end
    end
  end
  
  describe 'Workflow Templates and Customization' do
    it 'creates custom workflow from scratch' do
      sign_in manager
      visit workflow_designer_path
      
      within '.workflow-canvas' do
        # Drag and drop workflow elements
        drag_element('Start', to: '.canvas-area')
        drag_element('Condition', to: '.canvas-area')
        drag_element('Parallel Gateway', to: '.canvas-area')
        drag_element('Task', to: '.canvas-area', count: 2)
        drag_element('Merge Gateway', to: '.canvas-area')
        drag_element('End', to: '.canvas-area')
        
        # Connect elements
        connect_elements('start-node', 'condition-1')
        connect_elements('condition-1', 'parallel-1', label: 'Yes')
        connect_elements('condition-1', 'end-node', label: 'No')
        connect_elements('parallel-1', 'task-1')
        connect_elements('parallel-1', 'task-2')
        connect_elements('task-1', 'merge-1')
        connect_elements('task-2', 'merge-1')
        connect_elements('merge-1', 'end-node')
        
        # Configure elements
        double_click_element('condition-1')
        
        within '.element-config' do
          fill_in 'Label', with: 'Montant > 10k?'
          select 'Document.amount', from: 'field'
          select 'greater_than', from: 'operator'
          fill_in 'value', with: '10000'
          click_button 'Enregistrer'
        end
        
        double_click_element('task-1')
        
        within '.element-config' do
          fill_in 'Label', with: 'Validation financière'
          select 'Validation', from: 'task_type'
          select 'Finance Team', from: 'assignee'
          click_button 'Enregistrer'
        end
        
        double_click_element('task-2')
        
        within '.element-config' do
          fill_in 'Label', with: 'Validation juridique'
          select 'Validation', from: 'task_type'
          select 'Legal Team', from: 'assignee'
          click_button 'Enregistrer'
        end
      end
      
      # Save workflow
      click_button 'Enregistrer le workflow'
      
      within '.save-workflow-modal' do
        fill_in 'Nom', with: 'Validation parallèle conditionnelle'
        fill_in 'Description', with: 'Validation financière et juridique en parallèle pour montants > 10k'
        select 'Contrats', from: 'Catégorie'
        check 'Activer immédiatement'
        
        click_button 'Enregistrer'
      end
      
      expect(page).to have_content('Workflow enregistré avec succès')
      
      # Test workflow execution
      document = create(:document, amount: 15000, category: 'contract')
      WorkflowService.new(document).trigger_matching_workflows
      
      visit ged_document_path(document)
      
      within '.workflow-status' do
        expect(page).to have_content('Validation parallèle conditionnelle')
        expect(page).to have_content('2 tâches en cours')
        expect(page).to have_css('.parallel-indicator')
      end
    end
  end
  
  describe 'Workflow Monitoring and Analytics' do
    it 'monitors workflow performance' do
      sign_in manager
      visit workflow_analytics_path
      
      within '.workflow-metrics' do
        expect(page).to have_content('Performance des workflows')
        
        # KPIs
        within '.workflow-kpis' do
          expect(page).to have_content('Temps moyen de traitement')
          expect(page).to have_content('Taux de complétion')
          expect(page).to have_content('Workflows en retard')
          expect(page).to have_content('Goulots d\'étranglement')
        end
        
        # Workflow list with metrics
        within '.workflow-performance-table' do
          within '.workflow-row', text: 'Validation standard' do
            expect(page).to have_content('85%') # Completion rate
            expect(page).to have_content('2.5 jours') # Avg time
            expect(page).to have_content('125') # Total executions
            expect(page).to have_css('.performance-indicator.good')
          end
          
          within '.workflow-row', text: 'Approbation complexe' do
            expect(page).to have_content('72%') # Completion rate
            expect(page).to have_content('5.2 jours') # Avg time
            expect(page).to have_css('.performance-indicator.warning')
            
            click_link 'Analyser'
          end
        end
      end
      
      # Detailed workflow analysis
      within '.workflow-analysis' do
        expect(page).to have_content('Analyse: Approbation complexe')
        
        # Bottleneck identification
        within '.bottleneck-analysis' do
          expect(page).to have_content('Étape la plus lente: Validation Direction')
          expect(page).to have_content('Temps moyen: 3.1 jours')
          expect(page).to have_content('Recommandation: Ajouter des validateurs')
        end
        
        # Success/failure paths
        within '.path-analysis' do
          expect(page).to have_css('.sankey-diagram')
          expect(page).to have_content('28% rejets à l\'étape 2')
        end
      end
      
      # Optimize workflow
      click_button 'Optimiser ce workflow'
      
      within '.optimization-suggestions' do
        expect(page).to have_content('Suggestions d\'optimisation')
        
        within '.suggestion', text: 'Validation parallèle' do
          expect(page).to have_content('Réduirait le temps de 40%')
          click_button 'Appliquer'
        end
      end
      
      expect(page).to have_content('Workflow optimisé')
    end
  end
  
  private
  
  def drag_element(element_type, to:, count: 1)
    count.times do
      source = find(".workflow-element[data-type='#{element_type}']")
      target = find(to)
      source.drag_to(target)
    end
  end
  
  def connect_elements(from_id, to_id, label: nil)
    from = find("##{from_id} .connection-point.output")
    to = find("##{to_id} .connection-point.input")
    from.drag_to(to)
    
    if label
      connection = find(".connection[data-from='#{from_id}'][data-to='#{to_id}']")
      connection.double_click
      fill_in 'Label', with: label
      click_button 'OK'
    end
  end
  
  def double_click_element(element_id)
    find("##{element_id}").double_click
  end
end