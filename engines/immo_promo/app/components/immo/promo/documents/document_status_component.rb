module Immo
  module Promo
    module Documents
      class DocumentStatusComponent < ViewComponent::Base
        def initialize(document:, show_details: false)
          @document = document
          @show_details = show_details
        end

        private

        attr_reader :document, :show_details

        def status_config
          @status_config ||= {
            'draft' => {
              color: 'yellow',
              icon: 'pencil',
              label: 'Brouillon',
              description: 'Document en cours de rédaction'
            },
            'published' => {
              color: 'green',
              icon: 'check-circle',
              label: 'Publié',
              description: 'Document disponible et validé'
            },
            'locked' => {
              color: 'red',
              icon: 'lock-closed',
              label: 'Verrouillé',
              description: 'Document en cours de modification exclusive'
            },
            'archived' => {
              color: 'gray',
              icon: 'archive',
              label: 'Archivé',
              description: 'Document archivé et non modifiable'
            }
          }
        end

        def processing_status_config
          @processing_status_config ||= {
            'pending' => {
              color: 'yellow',
              icon: 'clock',
              label: 'En attente',
              description: 'Traitement en attente'
            },
            'processing' => {
              color: 'blue',
              icon: 'cog',
              label: 'En cours',
              description: 'Traitement en cours',
              spinning: true
            },
            'ai_processing' => {
              color: 'purple',
              icon: 'cpu-chip',
              label: 'IA en cours',
              description: 'Analyse IA en cours',
              spinning: true
            },
            'completed' => {
              color: 'green',
              icon: 'check',
              label: 'Terminé',
              description: 'Traitement terminé avec succès'
            },
            'failed' => {
              color: 'red',
              icon: 'exclamation-triangle',
              label: 'Échec',
              description: 'Erreur lors du traitement'
            }
          }
        end

        def validation_status_config
          @validation_status_config ||= {
            'none' => {
              color: 'gray',
              icon: 'minus',
              label: 'Aucune',
              description: 'Aucune validation requise'
            },
            'pending' => {
              color: 'yellow',
              icon: 'clock',
              label: 'En attente',
              description: 'Validation en attente'
            },
            'in_progress' => {
              color: 'blue',
              icon: 'eye',
              label: 'En cours',
              description: 'Validation en cours d\'examen'
            },
            'approved' => {
              color: 'green',
              icon: 'check-circle',
              label: 'Approuvé',
              description: 'Document validé et approuvé'
            },
            'rejected' => {
              color: 'red',
              icon: 'x-circle',
              label: 'Rejeté',
              description: 'Document rejeté lors de la validation'
            }
          }
        end

        def virus_scan_status_config
          @virus_scan_status_config ||= {
            'pending' => {
              color: 'yellow',
              icon: 'clock',
              label: 'Scan en attente',
              description: 'Analyse antivirus en attente'
            },
            'clean' => {
              color: 'green',
              icon: 'shield-check',
              label: 'Sain',
              description: 'Fichier sain, aucun virus détecté'
            },
            'infected' => {
              color: 'red',
              icon: 'shield-exclamation',
              label: 'Infecté',
              description: 'Virus détecté dans le fichier'
            },
            'error' => {
              color: 'red',
              icon: 'exclamation-triangle',
              label: 'Erreur scan',
              description: 'Erreur lors de l\'analyse antivirus'
            }
          }
        end

        def current_status_config
          status_config[document.status] || status_config['draft']
        end

        def current_processing_config
          processing_status_config[document.processing_status] || processing_status_config['pending']
        end

        def current_validation_config
          validation_status_config[document.validation_status] || validation_status_config['none']
        end

        def current_virus_scan_config
          virus_scan_status_config[document.virus_scan_status] || virus_scan_status_config['pending']
        end

        def has_lock?
          document.locked? && document.locked_by
        end

        def lock_info
          return unless has_lock?
          
          {
            user: document.locked_by.full_name,
            time: time_ago_in_words(document.locked_at),
            reason: document.lock_reason,
            scheduled_unlock: document.unlock_scheduled_at
          }
        end

        def ai_processing_info
          return unless document.ai_processed?
          
          {
            category: document.ai_classification_category,
            confidence: document.ai_classification_confidence_percent,
            processed_at: time_ago_in_words(document.ai_processed_at)
          }
        end

        def validation_info
          return unless document.current_validation_request
          
          summary = document.validation_summary
          {
            requester: summary[:requester],
            progress: summary[:progress],
            created_at: time_ago_in_words(summary[:created_at]),
            completed_at: summary[:completed_at] ? time_ago_in_words(summary[:completed_at]) : nil
          }
        end

        def processing_error?
          document.processing_status == 'failed' && document.processing_error.present?
        end

        def should_show_processing?
          !document.processing_status.in?(['completed']) || processing_error?
        end

        def should_show_validation?
          document.validation_status != 'none'
        end

        def should_show_virus_scan?
          document.virus_scan_status != 'clean' || show_details
        end

        def overall_status_color
          return 'red' if document.virus_scan_status == 'infected'
          return 'red' if document.processing_status == 'failed'
          return 'red' if document.validation_status == 'rejected'
          return 'yellow' if document.processing_status.in?(['pending', 'processing', 'ai_processing'])
          return 'yellow' if document.validation_status.in?(['pending', 'in_progress'])
          return 'green' if document.status == 'published' && document.processing_status == 'completed'
          
          current_status_config[:color]
        end

        def is_critical_issue?
          document.virus_scan_status == 'infected' ||
          document.processing_status == 'failed' ||
          document.validation_status == 'rejected'
        end

        def needs_attention?
          document.processing_status.in?(['pending', 'processing', 'ai_processing']) ||
          document.validation_status.in?(['pending', 'in_progress']) ||
          (has_lock? && document.unlock_scheduled_at && document.unlock_scheduled_at < Time.current)
        end
      end
    end
  end
end