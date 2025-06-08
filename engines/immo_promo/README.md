# ImmoPromo

ImmoPromo is a Rails engine that provides comprehensive real estate development project management features for Docusphere.

## Features

- Project management with phases and milestones
- Task tracking and assignment
- Stakeholder management
- Budget tracking and financial reporting
- Permit and contract management
- Risk assessment and mitigation
- Progress reporting

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'immo_promo', path: 'engines/immo_promo'
```

And then execute:
```bash
$ bundle
```

Mount the engine in your routes.rb:
```ruby
mount ImmoPromo::Engine => "/immo_promo"
```

Run migrations:
```bash
$ rails immo_promo:install:migrations
$ rails db:migrate
```

## Usage

The engine provides a complete project management system for real estate development projects.

### Models

- **Project**: Main project entity
- **Phase**: Project phases (studies, permits, construction, etc.)
- **Task**: Individual tasks within phases
- **Stakeholder**: Contractors, architects, engineers, etc.
- **Budget**: Financial tracking
- **Permit**: Building permits and approvals
- **Contract**: Stakeholder contracts
- **Risk**: Risk assessment and tracking

### Controllers

All controllers are namespaced under `ImmoPromo::` and inherit from the main application's `ApplicationController`.

## Configuration

The engine can be configured in an initializer:

```ruby
# config/initializers/immo_promo.rb
ImmoPromo.configure do |config|
  # Configuration options
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).