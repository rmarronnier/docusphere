#!/usr/bin/env ruby

# Script to fix all occurrences of user: to uploaded_by: in document creation

files_to_fix = [
  'spec/integration/document_validation_workflow_spec.rb',
  'spec/models/authorization_spec.rb',
  'spec/requests/document_api_spec.rb',
  'spec/requests/api/v1/documents_spec.rb',
  'spec/system/search_autocomplete_spec.rb',
  'spec/system/document_sharing_workflow_spec.rb',
  'spec/support/factory_helpers.rb',
  'spec/controllers/search_controller_spec.rb'
]

files_to_fix.each do |file|
  next unless File.exist?(file)
  
  content = File.read(file)
  original_content = content.dup
  
  # Replace user: with uploaded_by: in document creation
  content.gsub!(/create\(:document([^)]*)\buser:/, 'create(:document\1uploaded_by:')
  content.gsub!(/build\(:document([^)]*)\buser:/, 'build(:document\1uploaded_by:')
  
  if content != original_content
    File.write(file, content)
    puts "Fixed: #{file}"
  end
end

# Also fix any direct references to document.user
puts "\nFinding files with document.user references..."
`grep -r "document\\.user" spec/`.each_line do |line|
  file = line.split(':').first
  next unless File.exist?(file)
  
  content = File.read(file)
  original_content = content.dup
  
  # Replace document.user with document.uploaded_by
  content.gsub!(/(\bdocument\.user)\b/, 'document.uploaded_by')
  content.gsub!(/(\bdoc\.user)\b/, 'doc.uploaded_by')
  content.gsub!(/(\b@document\.user)\b/, '@document.uploaded_by')
  
  if content != original_content
    File.write(file, content)
    puts "Fixed document.user references in: #{file}"
  end
end

puts "\nDone!"