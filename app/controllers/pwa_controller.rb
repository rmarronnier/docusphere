class PwaController < ApplicationController
  def manifest
    render json: {
      name: "DocuSphere",
      short_name: "DocuSphere",
      description: "Plateforme de gestion documentaire",
      start_url: root_path,
      display: "standalone",
      background_color: "#ffffff",
      theme_color: "#3b82f6",
      icons: [
        {
          src: asset_path("icon.png"),
          sizes: "192x192",
          type: "image/png"
        }
      ]
    }
  end
end