class Ui::IconComponent < ApplicationComponent
  ICONS = {
    # Document/File icons
    document: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
    clipboard: 'M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2',
    
    # Status/Action icons
    check: 'M5 13l4 4L19 7',
    check_circle: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
    x_circle: 'M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z',
    exclamation: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z',
    information_circle: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    
    # Navigation icons
    plus: 'M12 4v16m8-8H4',
    minus: 'M20 12H4',
    chevron_down: 'M19 9l-7 7-7-7',
    chevron_up: 'M5 15l7-7 7 7',
    chevron_left: 'M15 19l-7-7 7-7',
    chevron_right: 'M9 5l7 7-7 7',
    menu: 'M4 6h16M4 12h16M4 18h16',
    x: 'M6 18L18 6M6 6l12 12',
    
    # Badge/Certificate icons
    badge_check: 'M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z',
    
    # Construction/Building icons
    office_building: 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4',
    home: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6',
    
    # Shopping/Commerce icons
    shopping_cart: 'M3 3h2l.4 2M7 13h10l4-8H5.4m-2.4 0L4.6 3M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17M17 13v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6',
    
    # Construction specific (ImmoPromo)
    construction: 'M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547A1.998 1.998 0 004 17.658V18a2 2 0 002 2h12a2 2 0 002-2v-.342a1.998 1.998 0 00-.572-1.43z'
  }.freeze
  
  def initialize(name:, size: 5, css_class: nil, viewbox: '0 0 24 24', stroke_width: 2)
    @name = name.to_sym
    @size = size
    @css_class = css_class
    @viewbox = viewbox
    @stroke_width = stroke_width
  end
  
  private
  
  def icon_path
    ICONS[@name]
  end
  
  def icon_classes
    base_classes = "h-#{@size} w-#{@size}"
    [@css_class, base_classes].compact.join(' ')
  end
end