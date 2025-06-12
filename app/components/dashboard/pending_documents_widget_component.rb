class Dashboard::PendingDocumentsWidgetComponent < ViewComponent::Base
  def initialize(documents:, user:)
    @documents = documents
    @user = user
  end
  
  private
  
  def any_documents?
    @documents.any?
  end
  
  def document_status_label(document)
    case document.status
    when 'draft'
      'Brouillon'
    when 'locked'
      'Verrouillé'
    when 'pending_validation'
      'En attente de validation'
    else
      document.status.humanize
    end
  end
  
  def document_status_color(document)
    case document.status
    when 'draft'
      'bg-gray-100 text-gray-800'
    when 'locked'
      'bg-yellow-100 text-yellow-800'
    when 'pending_validation'
      'bg-orange-100 text-orange-800'
    else
      'bg-blue-100 text-blue-800'
    end
  end
  
  def action_required_for(document)
    if document.status == 'draft'
      'Finaliser le document'
    elsif document.status == 'locked' && document.locked_by == @user
      'Déverrouiller le document'
    elsif document.validation_requests.pending.where(assigned_to: @user).any?
      'Valider le document'
    else
      'Consulter le document'
    end
  end
  
  def action_path_for(document)
    if document.status == 'draft'
      helpers.ged_edit_document_path(document)
    elsif document.validation_requests.pending.where(assigned_to: @user).any?
      helpers.ged_document_validation_requests_path(document)
    else
      helpers.ged_document_path(document)
    end
  end
  
  def action_icon_for(document)
    if document.status == 'draft'
      'pencil'
    elsif document.status == 'locked'
      'lock-open'
    elsif document.validation_requests.pending.where(assigned_to: @user).any?
      'check'
    else
      'eye'
    end
  end
  
  def format_file_size(size)
    return "0 B" unless size
    
    case size
    when 0..1.kilobyte
      "#{size} B"
    when 1.kilobyte..1.megabyte
      "#{(size.to_f / 1.kilobyte).round(1)} KB"
    when 1.megabyte..1.gigabyte
      "#{(size.to_f / 1.megabyte).round(1)} MB"
    else
      "#{(size.to_f / 1.gigabyte).round(2)} GB"
    end
  end
  
  def time_ago_in_words_short(time)
    return "À l'instant" unless time
    
    diff = Time.current - time
    
    case diff
    when 0..59
      "Il y a #{diff.to_i}s"
    when 60..3599
      "Il y a #{(diff / 60).to_i}m"
    when 3600..86399
      "Il y a #{(diff / 3600).to_i}h"
    when 86400..604799
      "Il y a #{(diff / 86400).to_i}j"
    else
      time.strftime("%d/%m/%Y")
    end
  end
end