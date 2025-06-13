class Dashboard::Widgets::MyDocumentsComponent < ViewComponent::Base
  def initialize(documents:)
    @documents = documents || []
  end

  private

  attr_reader :documents

  def any_documents?
    documents.any?
  end

  def status_badge_class(status)
    case status
    when 'draft'
      'bg-gray-100 text-gray-800'
    when 'active'
      'bg-green-100 text-green-800'
    when 'locked'
      'bg-yellow-100 text-yellow-800'
    when 'archived'
      'bg-blue-100 text-blue-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def status_label(status)
    case status
    when 'draft'
      'Brouillon'
    when 'active'
      'Actif'
    when 'locked'
      'Verrouillé'
    when 'archived'
      'Archivé'
    else
      status&.humanize || 'Inconnu'
    end
  end

  def format_timestamp(timestamp)
    return "à l'instant" unless timestamp

    diff = Time.current - timestamp

    case diff
    when 0..86399
      "aujourd'hui"
    when 86400..172799
      "hier"
    when 172800..604799
      days = (diff / 86400).to_i
      "il y a #{days} jours"
    else
      timestamp.strftime("%d/%m/%Y")
    end
  end
end