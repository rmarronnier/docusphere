# Selenium Testing Configuration

## Overview

This project uses a dedicated Selenium service for running system tests, which provides better isolation and stability compared to running Chrome/Chromium directly in the application container.

## Architecture

- **Selenium Service**: Runs as a separate Docker container
- **ARM64 Support**: Uses `seleniarm/standalone-chromium` for Apple Silicon Macs
- **x86_64 Support**: Uses `selenium/standalone-chrome` for Intel/GitHub Actions
- **Remote WebDriver**: Tests connect to Selenium via `http://selenium:4444/wd/hub`

## Running System Tests

### 🚨 IMPORTANT: Always use the provided script

**DO NOT** run system tests with plain `rspec` commands. **ALWAYS** use the `bin/system-test` script:

```bash
# ✅ CORRECT - Use the script
./bin/system-test

# ✅ CORRECT - Run specific test file
./bin/system-test spec/system/document_upload_workflow_spec.rb

# ✅ CORRECT - Run with specific RSpec options
./bin/system-test --fail-fast

# ❌ WRONG - Do not use plain docker-compose commands
# docker-compose run web rspec spec/system/

# ❌ WRONG - Do not use exec without proper setup
# docker-compose exec web rspec spec/system/
```

### Why use the script?

The `bin/system-test` script:
1. Ensures all required services are running (DB, Redis, Elasticsearch, Selenium)
2. Waits for services to be ready before running tests
3. Sets up the test database correctly
4. Configures the proper environment variables
5. Handles architecture detection (ARM64 vs x86_64)

### Script Behavior

When you run `./bin/system-test`:

1. **Service Startup**: Starts all required services (db, redis, elasticsearch, selenium)
2. **Health Checks**: Waits for all services to be ready
3. **Database Setup**: Prepares the test database
4. **Test Execution**: Runs tests with proper Docker networking
5. **Services Stay Running**: After tests complete, services remain running for debugging

### Manual Selenium Management (Advanced)

If you need to manage Selenium manually:

```bash
# Start Selenium service
docker-compose up -d selenium

# Check Selenium status
curl http://localhost:4444/wd/hub/status

# View browser session (VNC) - useful for debugging
open http://localhost:7900

# Stop Selenium
docker-compose stop selenium
```

## Configuration Details

### Capybara Configuration

The Capybara configuration (`spec/support/capybara.rb`) is optimized for Docker:

- **Server Host**: Binds to `0.0.0.0` in Docker for network accessibility
- **Server Port**: Uses port 3001 to avoid conflicts
- **App Host**: Dynamically determined based on container hostname
- **Driver**: Automatically uses remote Selenium when in Docker
- **Timeouts**: Increased to 10 seconds for Docker environment

### Chrome Options

The Chrome browser is configured with these options for stability:
- `--headless`: Runs without GUI
- `--no-sandbox`: Required for Docker
- `--disable-dev-shm-usage`: Prevents shared memory issues
- `--disable-gpu`: Improves stability
- `--window-size=1920,1080`: Consistent viewport size

### System Test Helper

The `SystemTestHelper` module provides common functionality:
- `login_as_user(user)`: Login helper using Warden
- `wait_for_ajax`: Wait for AJAX requests
- `capture_screenshot(name)`: Take named screenshots
- `element_visible?(selector)`: Check element visibility
- `debug_here`: Pause execution when DEBUG=1

## Writing System Tests

### Basic Structure

```ruby
require 'rails_helper'

RSpec.describe "Feature Name", type: :system do
  let(:user) { create(:user) }
  
  before do
    login_as(user, scope: :user)
  end
  
  # Tests that require JavaScript
  it "does something with JavaScript", js: true do
    visit some_path
    click_button "Action"
    expect(page).to have_content("Result")
  end
  
  # Tests without JavaScript (faster)
  it "does something without JavaScript" do
    visit some_path
    expect(page).to have_content("Content")
  end
end
```

### Best Practices

1. **Use `js: true` only when needed**: Non-JS tests are faster
2. **Wait for elements**: Use Capybara's built-in waiting
3. **Avoid sleep**: Use `have_content` with wait instead
4. **Clean state**: Each test should be independent
5. **Screenshots**: Failed tests automatically save screenshots

## Debugging Tests

### View Live Browser

1. Ensure Selenium is running: `docker-compose ps selenium`
2. Open VNC viewer: `open http://localhost:7900`
3. No password required
4. You'll see the browser executing tests in real-time

### Debug Mode

Add `debug: true` to pause and see the browser:

```ruby
it "complex interaction", debug: true do
  # Browser will be visible, not headless
end
```

Or use `debug_here` in your test:

```ruby
it "needs debugging" do
  visit some_path
  debug_here  # Pauses when DEBUG=1 is set
  click_button "Action"
end
```

Run with DEBUG environment variable:
```bash
DEBUG=1 ./bin/system-test spec/system/specific_spec.rb
```

### Screenshots

Failed tests automatically save screenshots to `tmp/screenshots/`.

## Troubleshooting

### Common Issues and Solutions

#### 1. "Failed to open TCP connection to selenium:4444"
**Solution**: Selenium service is not running. Use `./bin/system-test` script which handles this automatically.

#### 2. "net::ERR_NAME_NOT_RESOLVED" or "net::ERR_CONNECTION_REFUSED"
**Solution**: Network configuration issue. The script handles proper networking setup.

#### 3. "ActiveRecord::EnvironmentMismatchError"
**Solution**: Database environment mismatch. The script runs `db:prepare` automatically.

#### 4. Tests timeout frequently
**Solution**: 
- Check if services are healthy: `docker-compose ps`
- Increase timeout in `spec/support/capybara.rb`
- Ensure your computer has enough resources

#### 5. Different behavior locally vs CI
**Solution**: 
- Check architecture (ARM64 vs x86_64)
- Ensure same Chrome version
- Use the script which handles architecture detection

### Logs and Debugging

View Selenium logs:
```bash
docker-compose logs -f selenium
```

View Rails test logs:
```bash
docker-compose exec web tail -f log/test.log
```

## CI/CD Integration

For GitHub Actions, the script automatically detects and uses x86_64 configuration:

```yaml
- name: Run system tests
  run: ./bin/system-test
```

## Architecture-Specific Notes

### Apple Silicon (M1/M2)
- Uses `seleniarm/standalone-chromium`
- May need to pull image manually first time:
  ```bash
  docker pull seleniarm/standalone-chromium:latest
  ```

### Intel/GitHub Actions
- Uses `selenium/standalone-chrome`
- Handled automatically by docker-compose.selenium-x86.yml overlay

## Performance Tips

1. **Parallel Execution**: Not recommended for system tests due to port conflicts
2. **Headless Mode**: Always used by default for speed
3. **Service Reuse**: Keep services running between test runs
4. **Database Cleaning**: Uses transactions for speed

## Summary

- **Always use `./bin/system-test`** for running system tests
- Tests run in isolated Docker environment
- Automatic screenshot on failure
- VNC access for debugging at http://localhost:7900
- Services stay running after tests for debugging