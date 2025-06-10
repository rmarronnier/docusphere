# Lookbook configuration
Rails.application.configure do
  if defined?(Lookbook)
    config.lookbook.project_name = "Docusphere Components"
    config.lookbook.ui_theme = "zinc"
    
    # Preview paths (default is test/components/previews)
    config.lookbook.preview_paths = [
      Rails.root.join("test/components/previews")
    ]
    
    # Component paths (for source code display)
    config.lookbook.page_paths = [
      Rails.root.join("app/components")
    ]
    
    # Enable experimental features
    config.lookbook.experimental_features = true
    
    # Custom favicon
    # config.lookbook.ui_favicon = "/path/to/favicon.ico"
    
    # Custom CSS
    # config.lookbook.preview_stylesheets = ["/assets/application"]
    
    # Enable component search
    config.lookbook.enable_search = true
    
    # Display options
    config.lookbook.preview_display_options = {
      theme: ["light", "dark"],
      viewport: ["mobile", "tablet", "desktop"]
    }
    
    # Debug in development
    config.lookbook.debug = Rails.env.development?
  end
end