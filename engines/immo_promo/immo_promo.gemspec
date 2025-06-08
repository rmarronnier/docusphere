require_relative "lib/immo_promo/version"

Gem::Specification.new do |spec|
  spec.name        = "immo_promo"
  spec.version     = ImmoPromo::VERSION
  spec.authors     = ["Docusphere Team"]
  spec.email       = ["contact@docusphere.fr"]
  spec.homepage    = "https://github.com/docusphere/immo_promo"
  spec.summary     = "Real estate project management engine for Docusphere"
  spec.description = "A Rails engine providing real estate development project management features"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "pg"
  spec.add_dependency "money-rails"
  spec.add_dependency "aasm"
  spec.add_dependency "audited"
  
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
end