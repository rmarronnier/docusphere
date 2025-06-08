#!/usr/bin/env ruby

# Script to fix all user vs uploaded_by issues in specs

files_to_fix = [
  "spec/models/user_spec.rb",
  "spec/models/workflow_spec.rb", 
  "spec/models/basket_spec.rb",
  "spec/models/tag_spec.rb"
]

files_to_fix.each do |file|
  if File.exist?(file)
    content = File.read(file)
    
    # Fix user association to uploaded_by in document relations
    content.gsub!(/document\.user/, 'document.uploaded_by')
    content.gsub!(/documents\.create.*user:/, 'documents.create(uploaded_by:')
    content.gsub!(/create\(:document, user:/, 'create(:document, uploaded_by:')
    
    # Fix workflow association (should be organization not user)
    content.gsub!(/belong_to\(:user\)\.required/, 'belong_to(:organization).required')
    
    # Fix basket_items association (polymorphic)
    content.gsub!(/have_many\(:documents\)\.through\(:basket_items\)/, 'have_many(:items).through(:basket_items)')
    
    File.write(file, content)
    puts "Fixed: #{file}"
  else
    puts "Skipped (not found): #{file}"
  end
end

puts "Done!"