#!/usr/bin/env ruby

# Script to fix user vs uploaded_by in controller specs

Dir.glob("spec/controllers/**/*_spec.rb").each do |file|
  content = File.read(file)
  
  # Fix create(:document, user: ...) to create(:document, uploaded_by: ...)
  content.gsub!(/create\(:document, user:/, 'create(:document, uploaded_by:')
  
  # Fix Document.create(user: ...) to Document.create(uploaded_by: ...)
  content.gsub!(/Document\.create.*user:/, 'Document.create(uploaded_by:')
  
  # Fix documents.create(user: ...) to documents.create(uploaded_by: ...)
  content.gsub!(/documents\.create.*user:/, 'documents.create(uploaded_by:')
  
  # Fix document: { user_id: to document: { uploaded_by_id:
  content.gsub!(/document: \{ user_id:/, 'document: { uploaded_by_id:')
  
  # Fix params user_id to uploaded_by_id
  content.gsub!(/params.*user_id/, 'params.require(:document).permit(:title, :description, :file, :space_id, :folder_id).merge(uploaded_by_id:')
  
  File.write(file, content)
  puts "Fixed: #{file}"
end

puts "Done!"