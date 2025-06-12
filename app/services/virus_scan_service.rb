class VirusScanService
  def initialize(file_path)
    @file_path = file_path
  end

  def scan
    # Simulation d'un scan antivirus
    # En production, on utiliserait un service comme ClamAV
    {
      clean: true,
      virus_name: nil,
      scanned_at: Time.current
    }
  end

  def self.scan_file(file_path)
    new(file_path).scan
  end
end