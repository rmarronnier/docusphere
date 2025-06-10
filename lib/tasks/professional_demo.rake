namespace :db do
  desc "Seed professional demo data for DocuSphere"
  task professional_demo: :environment do
    puts "🚀 Loading Professional Demo Data..."
    
    # Load the professional demo seed file
    load Rails.root.join('db', 'seeds', 'professional_demo.rb')
    
    puts "✅ Professional demo data loaded successfully!"
  end
end