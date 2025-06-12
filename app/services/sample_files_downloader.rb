# Service pour télécharger des fichiers d'exemple depuis des sources publiques
require 'open-uri'
require 'net/http'

class SampleFilesDownloader
  SAMPLE_SOURCES = {
    # Documents PDF
    pdf: [
      { url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', name: 'Guide technique installation.pdf' },
      { url: 'https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf', name: 'Manuel utilisateur système.pdf' },
      { url: 'https://www.clickdimensions.com/links/TestPDFfile.pdf', name: 'Rapport conformité RGPD.pdf' }
    ],
    
    # Images
    images: [
      { url: 'https://picsum.photos/1920/1080', name: 'Plan étage principal.jpg' },
      { url: 'https://picsum.photos/1600/900', name: 'Vue 3D bâtiment.jpg' },
      { url: 'https://picsum.photos/2000/1200', name: 'Photo chantier facade.jpg' },
      { url: 'https://via.placeholder.com/1200x800/0066CC/FFFFFF?text=Plans+Architecturaux', name: 'Plans architecturaux.png' },
      { url: 'https://via.placeholder.com/800x600/FF6600/FFFFFF?text=Schema+Electrique', name: 'Schema electrique.png' }
    ],
    
    # Documents texte (créés localement)
    text: [
      { content: "# Contrat de Construction\n\nEntre les soussignés...\n\nArticle 1: Objet\nLe présent contrat a pour objet...", name: 'Contrat construction.txt' },
      { content: "SPECIFICATIONS TECHNIQUES\n\n1. Fondations\n- Béton armé C25/30\n- Profondeur: 1.5m\n\n2. Structure\n- Poteaux BA...", name: 'Specifications techniques.txt' },
      { content: "NOTE DE CALCUL STRUCTURE\n\nProjet: Tour Horizon\nDate: #{Date.today}\n\nCharges permanentes: 5 kN/m²\nCharges d'exploitation: 2.5 kN/m²", name: 'Note calcul structure.txt' }
    ],
    
    # Documents Office (utilisation de fichiers publics de test)
    office: [
      { url: 'https://file-examples.com/storage/fe1170c2816762d3e29bbc0/2017/02/file_example_XLSX_10.xlsx', name: 'Budget previsionnel.xlsx' },
      { url: 'https://file-examples.com/storage/fe1170c2816762d3e29bbc0/2017/02/file_example_XLS_10.xls', name: 'Planning travaux.xls' },
      { content: "Compte rendu de réunion\n\nDate: #{Date.today}\nParticipants: Direction, Chef de projet, Architecte\n\nOrdre du jour:\n1. Avancement travaux\n2. Budget\n3. Délais", name: 'CR reunion chantier.doc' }
    ],
    
    # Fichiers CAD/techniques (simulés avec des PDFs)
    cad: [
      { url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', name: 'Plan AutoCAD RDC.dwg.pdf' },
      { url: 'https://www.clickdimensions.com/links/TestPDFfile.pdf', name: 'Maquette BIM Structure.ifc.pdf' }
    ],
    
    # Archives
    archives: [
      { content: "Archive contenant:\n- Plans d'exécution\n- Notes de calcul\n- Rapports d'étude", name: 'Dossier technique complet.zip' }
    ],
    
    # Vidéos (utilisation de vidéos de test publiques)
    videos: [
      { url: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4', name: 'Visite virtuelle batiment.mp4' },
      { url: 'https://www.w3schools.com/html/mov_bbb.mp4', name: 'Time-lapse construction.mp4' }
    ]
  }.freeze

  def initialize
    @download_dir = Rails.root.join('tmp', 'sample_files')
    FileUtils.mkdir_p(@download_dir)
  end

  def download_all
    puts "📥 Téléchargement des fichiers d'exemple..."
    
    downloaded_files = {}
    
    SAMPLE_SOURCES.each do |category, files|
      puts "\n📁 Catégorie: #{category}"
      downloaded_files[category] = []
      
      files.each do |file_info|
        begin
          if file_info[:url]
            file_path = download_from_url(file_info[:url], file_info[:name])
          elsif file_info[:content]
            file_path = create_local_file(file_info[:content], file_info[:name])
          end
          
          if file_path && File.exist?(file_path)
            downloaded_files[category] << file_path
            puts "  ✅ #{file_info[:name]}"
          end
        rescue => e
          puts "  ❌ Erreur pour #{file_info[:name]}: #{e.message}"
        end
      end
    end
    
    puts "\n✅ Téléchargement terminé!"
    downloaded_files
  end

  def download_category(category)
    files = SAMPLE_SOURCES[category] || []
    downloaded = []
    
    files.each do |file_info|
      begin
        if file_info[:url]
          file_path = download_from_url(file_info[:url], file_info[:name])
        elsif file_info[:content]
          file_path = create_local_file(file_info[:content], file_info[:name])
        end
        
        downloaded << file_path if file_path && File.exist?(file_path)
      rescue => e
        Rails.logger.error "Erreur téléchargement #{file_info[:name]}: #{e.message}"
      end
    end
    
    downloaded
  end

  def cleanup_downloads
    FileUtils.rm_rf(@download_dir)
    FileUtils.mkdir_p(@download_dir)
  end

  private

  def download_from_url(url, filename)
    file_path = @download_dir.join(filename)
    
    # Skip if already downloaded
    return file_path if File.exist?(file_path)
    
    URI.open(url) do |remote_file|
      File.open(file_path, 'wb') do |local_file|
        local_file.write(remote_file.read)
      end
    end
    
    file_path
  rescue => e
    # Fallback: create a placeholder file
    create_placeholder_file(filename)
  end

  def create_local_file(content, filename)
    file_path = @download_dir.join(filename)
    File.write(file_path, content)
    file_path
  end

  def create_placeholder_file(filename)
    file_path = @download_dir.join(filename)
    extension = File.extname(filename).downcase
    
    content = case extension
    when '.pdf'
      "%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    when '.jpg', '.jpeg', '.png'
      # Create a minimal valid PNG
      [137, 80, 78, 71, 13, 10, 26, 10].pack('C*')
    when '.mp4', '.avi', '.mov'
      # Create a minimal video file header
      "ftypisom"
    when '.xlsx', '.xls'
      # Create a minimal Excel file
      "PK\x03\x04"
    when '.doc', '.docx'
      # Create a minimal Word file
      "{\rtf1\ansi\deff0 {\fonttbl{\f0 Times New Roman;}} \f0\fs24 Document placeholder\par}"
    when '.zip'
      # Create a minimal zip file
      "PK\x05\x06" + "\x00" * 18
    else
      "Fichier exemple: #{filename}\nCréé le: #{Time.current}\nType: #{extension}"
    end
    
    File.binwrite(file_path, content)
    file_path
  end
end