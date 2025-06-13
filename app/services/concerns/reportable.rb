# Concern for services that generate reports
module Reportable
  extend ActiveSupport::Concern

  included do
    attr_reader :report_data, :report_options
  end

  # Generate report in multiple formats
  def generate_report(format: :hash, options: {})
    @report_options = options
    @report_data = build_report_data
    
    case format.to_sym
    when :pdf
      generate_pdf_report
    when :excel, :xlsx
      generate_excel_report
    when :csv
      generate_csv_report
    when :json
      generate_json_report
    else
      @report_data
    end
  end

  # Export report with filename and headers
  def export_report(format: :pdf, filename: nil)
    content = generate_report(format: format)
    filename ||= default_filename(format)
    
    {
      content: content,
      filename: filename,
      content_type: content_type_for(format),
      disposition: 'attachment'
    }
  end

  private

  # To be implemented by including services
  def build_report_data
    raise NotImplementedError, "Services must implement build_report_data"
  end

  def generate_pdf_report
    require 'prawn'
    
    Prawn::Document.new do |pdf|
      pdf.text report_title, size: 20, style: :bold
      pdf.move_down 20
      
      render_report_sections(pdf)
      
      pdf.number_pages "Page <page> sur <total>", 
                      at: [pdf.bounds.right - 100, 0],
                      align: :right
    end.render
  end

  def generate_excel_report
    require 'axlsx'
    
    package = Axlsx::Package.new
    workbook = package.workbook
    
    workbook.add_worksheet(name: report_title) do |sheet|
      render_excel_sections(sheet)
    end
    
    package.to_stream.read
  end

  def generate_csv_report
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      render_csv_sections(csv)
    end
  end

  def generate_json_report
    {
      title: report_title,
      generated_at: Time.current,
      data: @report_data,
      options: @report_options
    }.to_json
  end

  def render_report_sections(pdf)
    if @report_data.is_a?(Hash)
      @report_data.each do |section, data|
        render_pdf_section(pdf, section.to_s.humanize, data)
      end
    elsif @report_data.is_a?(Array)
      render_pdf_table(pdf, @report_data)
    end
  end

  def render_pdf_section(pdf, title, data)
    pdf.text title, size: 16, style: :bold
    pdf.move_down 10
    
    if data.is_a?(Array)
      render_pdf_table(pdf, data)
    elsif data.is_a?(Hash)
      data.each { |k, v| pdf.text "#{k.to_s.humanize}: #{v}" }
    else
      pdf.text data.to_s
    end
    
    pdf.move_down 15
  end

  def render_pdf_table(pdf, data)
    return unless data.present? && data.first.is_a?(Hash)
    
    headers = data.first.keys.map(&:to_s).map(&:humanize)
    rows = data.map { |row| row.values }
    
    pdf.table([headers] + rows, header: true) do
      style(row(0), background_color: 'EEEEEE', font_style: :bold)
      self.width = pdf.bounds.width
    end
  end

  def render_excel_sections(sheet)
    if @report_data.is_a?(Hash)
      row_index = 1
      @report_data.each do |section, data|
        sheet.add_row [section.to_s.humanize], style: sheet.styles.add_style(b: true, sz: 14)
        row_index += 1
        
        if data.is_a?(Array) && data.first.is_a?(Hash)
          headers = data.first.keys.map(&:to_s).map(&:humanize)
          sheet.add_row headers, style: sheet.styles.add_style(b: true)
          
          data.each do |row|
            sheet.add_row row.values
          end
        end
        row_index += data.size + 2
      end
    end
  end

  def render_csv_sections(csv)
    if @report_data.is_a?(Array) && @report_data.first.is_a?(Hash)
      headers = @report_data.first.keys.map(&:to_s).map(&:humanize)
      csv << headers
      
      @report_data.each do |row|
        csv << row.values
      end
    end
  end

  def report_title
    @report_options[:title] || "#{self.class.name.demodulize.humanize} Report"
  end

  def default_filename(format)
    base = report_title.parameterize
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    "#{base}_#{timestamp}.#{format}"
  end

  def content_type_for(format)
    case format.to_sym
    when :pdf
      'application/pdf'
    when :excel, :xlsx
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when :csv
      'text/csv'
    when :json
      'application/json'
    else
      'application/octet-stream'
    end
  end
end