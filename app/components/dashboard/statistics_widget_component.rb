class Dashboard::StatisticsWidgetComponent < ViewComponent::Base
  def initialize(stats:)
    @stats = stats || {}
  end
  
  private
  
  def statistics
    [
      {
        label: "Documents totaux",
        value: @stats[:total_documents] || 0,
        icon: "document",
        color: "blue",
        change: calculate_change(:total_documents),
        trend: trend_for(:total_documents)
      },
      {
        label: "En attente",
        value: @stats[:pending_validations] || 0,
        icon: "clock",
        color: "orange",
        change: calculate_change(:pending_validations),
        trend: trend_for(:pending_validations)
      },
      {
        label: "Partagés",
        value: @stats[:shared_documents] || 0,
        icon: "share",
        color: "purple",
        change: calculate_change(:shared_documents),
        trend: trend_for(:shared_documents)
      },
      {
        label: "Stockage utilisé",
        value: @stats[:storage_used] || "0 B",
        icon: "database",
        color: "green",
        subtitle: "sur 10 GB",
        percentage: storage_percentage
      }
    ]
  end
  
  def calculate_change(stat_type)
    # En production, comparer avec période précédente
    # Pour la démo, valeurs fictives
    case stat_type
    when :total_documents
      "+12%"
    when :pending_validations
      "-5%"
    when :shared_documents
      "+8%"
    else
      "0%"
    end
  end
  
  def trend_for(stat_type)
    change = calculate_change(stat_type)
    return "stable" if change == "0%"
    change.start_with?("+") ? "up" : "down"
  end
  
  def storage_percentage
    # Calcul du pourcentage d'utilisation
    return 0 unless @stats[:storage_used]
    
    # Convertir en bytes
    used_bytes = parse_storage_size(@stats[:storage_used])
    total_bytes = 10.gigabytes
    
    ((used_bytes.to_f / total_bytes) * 100).round(1)
  end
  
  def parse_storage_size(size_string)
    return 0 unless size_string.is_a?(String)
    
    match = size_string.match(/^([\d.]+)\s*(\w+)$/)
    return 0 unless match
    
    value = match[1].to_f
    unit = match[2].downcase
    
    case unit
    when 'b'
      value
    when 'kb'
      value.kilobytes
    when 'mb'
      value.megabytes
    when 'gb'
      value.gigabytes
    else
      0
    end
  end
  
  def stat_icon_svg(icon_name)
    case icon_name
    when "document"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>'
    when "clock"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    when "share"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.032 4.026a3 3 0 10-5.464 0m5.464 0a3 3 0 10-5.464 0M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
    when "database"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4"></path>'
    else
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>'
    end
  end
  
  def stat_color_classes(color)
    {
      icon: case color
            when "blue" then "text-blue-600 bg-blue-100"
            when "orange" then "text-orange-600 bg-orange-100"
            when "purple" then "text-purple-600 bg-purple-100"
            when "green" then "text-green-600 bg-green-100"
            else "text-gray-600 bg-gray-100"
            end,
      trend: case color
             when "blue" then "text-blue-600"
             when "orange" then "text-orange-600"
             when "purple" then "text-purple-600"
             when "green" then "text-green-600"
             else "text-gray-600"
             end
    }
  end
  
  def trend_icon_svg(trend)
    case trend
    when "up"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"></path>'
    when "down"
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>'
    else
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14"></path>'
    end
  end
end