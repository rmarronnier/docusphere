class Ui::StatusBadgeComponent < ApplicationComponent
  PRESETS = {
    # Generic statuses
    active: { color: :green, label: 'Active' },
    inactive: { color: :gray, label: 'Inactive' },
    pending: { color: :yellow, label: 'Pending' },
    completed: { color: :green, label: 'Completed' },
    in_progress: { color: :blue, label: 'In Progress' },
    delayed: { color: :red, label: 'Delayed' },
    cancelled: { color: :gray, label: 'Cancelled' },
    draft: { color: :gray, label: 'Draft' },
    published: { color: :green, label: 'Published' },
    archived: { color: :gray, label: 'Archived' },
    
    # Project/Phase specific
    not_started: { color: :gray, label: 'Not Started' },
    on_hold: { color: :yellow, label: 'On Hold' },
    at_risk: { color: :orange, label: 'At Risk' },
    on_track: { color: :green, label: 'On Track' }
  }.freeze
  
  COLORS = {
    gray: 'bg-gray-100 text-gray-800',
    red: 'bg-red-100 text-red-800',
    yellow: 'bg-yellow-100 text-yellow-800',
    green: 'bg-green-100 text-green-800',
    blue: 'bg-blue-100 text-blue-800',
    indigo: 'bg-indigo-100 text-indigo-800',
    purple: 'bg-purple-100 text-purple-800',
    pink: 'bg-pink-100 text-pink-800',
    orange: 'bg-orange-100 text-orange-800'
  }.freeze
  
  def initialize(status: nil, label: nil, color: nil, size: :medium, dot: false, removable: false)
    if status && PRESETS[status.to_sym]
      preset = PRESETS[status.to_sym]
      @label = label || preset[:label]
      @color = color || preset[:color]
    else
      @label = label || status&.to_s&.humanize || 'Unknown'
      @color = color || :gray
    end
    
    @size = size
    @dot = dot
    @removable = removable
  end
  
  private
  
  def badge_classes
    base = 'inline-flex items-center font-medium rounded-full'
    size_classes = case @size
                   when :small
                     'px-2.5 py-0.5 text-xs'
                   when :large
                     'px-4 py-1.5 text-sm'
                   else # :medium
                     'px-3 py-1 text-xs'
                   end
    color_classes = COLORS[@color.to_sym] || COLORS[:gray]
    
    "#{base} #{size_classes} #{color_classes}"
  end
  
  def dot_color_class
    case @color.to_sym
    when :gray then 'bg-gray-400'
    when :red then 'bg-red-400'
    when :yellow then 'bg-yellow-400'
    when :green then 'bg-green-400'
    when :blue then 'bg-blue-400'
    when :indigo then 'bg-indigo-400'
    when :purple then 'bg-purple-400'
    when :pink then 'bg-pink-400'
    when :orange then 'bg-orange-400'
    else 'bg-gray-400'
    end
  end
  
end