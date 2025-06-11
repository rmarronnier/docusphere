namespace :dev do
  desc "Setup development environment with route validation"
  task setup: :environment do
    puts "🚀 Setting up development environment..."
    
    # Setup Git hooks
    puts "📌 Installing Git hooks..."
    system("./bin/setup-git-hooks")
    
    # Run initial route audit
    puts "🔍 Running initial route audit..."
    Rake::Task["routes:audit"].invoke
    
    # Setup database if needed
    unless ActiveRecord::Base.connection.tables.any?
      puts "🗄️  Setting up database..."
      Rake::Task["db:setup"].invoke
    end
    
    puts "✅ Development environment ready!"
    puts ""
    puts "💡 Available route commands:"
    puts "   rake routes:audit           - Audit all routes"
    puts "   rake routes:fix_common_issues - Auto-fix ViewComponent issues"
    puts "   rake dev:validate_routes    - Full validation suite"
    puts "   ./bin/pre-commit           - Manual pre-commit check"
  end
  
  desc "Run comprehensive route validation"
  task validate_routes: :environment do
    puts "🔍 Running comprehensive route validation..."
    
    # 1. Route audit
    puts "\n📋 1/3 - Route Audit"
    Rake::Task["routes:audit"].invoke
    
    # 2. Route tests
    puts "\n🧪 2/3 - Route Tests" 
    system("bundle exec rspec spec/routing/ --format progress") or exit(1)
    
    # 3. Navigation tests
    puts "\n🌐 3/3 - Navigation Tests"
    system("bundle exec rspec spec/system/navigation_paths_spec.rb --format progress") or exit(1)
    
    puts "\n✅ All route validations passed!"
  end
  
  desc "Fix all fixable route issues"
  task fix_routes: :environment do
    puts "🔧 Fixing route issues..."
    
    # Auto-fix ViewComponent issues
    puts "📝 Fixing ViewComponent route helpers..."
    Rake::Task["routes:fix_common_issues"].invoke
    
    # Run audit to show remaining issues
    puts "\n📋 Remaining issues after auto-fix:"
    Rake::Task["routes:audit"].invoke
    
    puts "\n💡 Manual fixes may be needed for remaining issues"
  end
end