namespace :demo do
  desc "Setup minimal demo environment"
  task setup: :environment do
    puts "🚀 Setting up demo environment..."
    
    # Clear existing data
    puts "🧹 Cleaning existing data..."
    Rake::Task['db:drop'].invoke rescue nil
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    
    # Load minimal seeds
    puts "🌱 Loading essential data..."
    ENV['SEED_TYPE'] = 'essential'
    Rake::Task['db:seed'].invoke
    ENV.delete('SEED_TYPE')
    
    # Load demo data
    puts "📊 Loading demo data..."
    load Rails.root.join('db/demo_minimal.rb')
    
    puts "✅ Demo environment ready!"
    puts ""
    puts "Login: admin@docusphere.fr / password123"
    puts "URL: http://localhost:3000"
  end

  desc "Quick health check"
  task health_check: :environment do
    puts "🏥 Health Check"
    puts "=" * 40
    
    # Check database
    begin
      user_count = User.count
      doc_count = Document.count
      puts "✅ Database: #{user_count} users, #{doc_count} documents"
    rescue => e
      puts "❌ Database error: #{e.message}"
    end
    
    # Check ImmoPromo
    if defined?(Immo::Promo::Project)
      project_count = Immo::Promo::Project.count
      puts "✅ ImmoPromo: #{project_count} projects"
    else
      puts "❌ ImmoPromo module not loaded"
    end
    
    # Check storage
    storage_path = Rails.root.join('storage')
    if Dir.exist?(storage_path)
      puts "✅ Storage directory exists"
    else
      puts "❌ Storage directory missing"
    end
    
    # Check sample documents
    sample_docs = Dir.glob(Rails.root.join("storage/sample_documents/*.{pdf,md}"))
    puts "✅ Sample documents: #{sample_docs.count} files"
  end

  desc "Reset to clean state (emergency)"
  task reset: :environment do
    puts "🚨 Emergency reset..."
    
    # Force reset
    ActiveRecord::Base.connection.tables.each do |table|
      next if table == 'schema_migrations' || table == 'ar_internal_metadata'
      ActiveRecord::Base.connection.execute("TRUNCATE #{table} CASCADE")
    end
    
    # Reload essential data
    ENV['SEED_TYPE'] = 'essential'
    Rake::Task['db:seed'].invoke
    
    puts "✅ Reset complete - minimal data loaded"
  end

  desc "Test critical paths"
  task test_critical: :environment do
    puts "🧪 Testing critical paths..."
    
    # Run only critical path tests
    system("bundle exec rspec spec/system/demo_critical_paths_spec.rb --format documentation")
  end
end