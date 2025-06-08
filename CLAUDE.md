# CLAUDE.md - AI Assistant Instructions

## Testing Requirements

**IMPORTANT**: For every new feature or functionality added to the codebase, you MUST:
1. Write corresponding RSpec tests (unit tests, integration tests, or system tests as appropriate)
2. Ensure tests cover both happy paths and edge cases
3. Run tests to verify they pass before considering the feature complete
4. Follow existing test patterns and conventions in the codebase
5. Update GitHub Actions workflows (.github/workflows/) if new dependencies or test configurations are needed

## Running Ruby Commands

All Ruby-dependent commands (such as `rspec`, `bundle`, `rails`, etc.) should be run inside a Docker container. Use the following patterns:

### Running Tests

#### Initial Setup for Parallel Tests
```bash
# First time setup - create parallel test databases
./bin/parallel_test_setup
```

#### Running Tests
```bash
# Run tests in parallel (RECOMMENDED - faster, default for CI)
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec

# Run tests in parallel with fail-fast
docker-compose run --rm -e PARALLEL_TEST_PROCESSORS=4 web bundle exec parallel_rspec --fail-fast

# Run tests sequentially with fail-fast to quickly identify first failure
docker-compose run --rm web bundle exec rspec --fail-fast

# Run full test suite sequentially
docker-compose run --rm web bundle exec rspec --format progress

# Run specific test file
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb

# Run specific test by line number
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb:42
```

Note: 
- Parallel tests use 4 processors by default to avoid database connection issues
- Test databases: docusphere_test, docusphere_test2, docusphere_test3, docusphere_test4
- Always use `PARALLEL_TEST_PROCESSORS=4` to ensure stable parallel execution

### Running Bundle Commands
```bash
docker-compose run --rm web bundle install
docker-compose run --rm web bundle update
```

### Running Rails Commands
```bash
docker-compose run --rm web rails db:migrate
docker-compose run --rm web rails db:seed
docker-compose run --rm web rails console
```

### Running Rake Tasks
```bash
docker-compose run --rm web rake db:setup
```

## Project-Specific Notes

- PostgreSQL reserved word: GROUP is a reserved keyword, use UserGroup model instead
- Test setup requires `require 'pundit/rspec'` in rails_helper.rb
- ViewComponent tests need `helpers.policy` instead of direct `policy` calls
- Test environment needs `config.hosts.clear` to avoid host blocking issues