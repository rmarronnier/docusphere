# Selenium Testing Configuration

## Overview

This project uses a dedicated Selenium service for running system tests, which provides better isolation and stability compared to running Chrome/Chromium directly in the application container.

## Architecture

- **Selenium Service**: Runs as a separate Docker container
- **ARM64 Support**: Uses `seleniarm/standalone-chromium` for Apple Silicon Macs
- **x86_64 Support**: Uses `selenium/standalone-chrome` for Intel/GitHub Actions
- **Remote WebDriver**: Tests connect to Selenium via `http://selenium:4444/wd/hub`

## Running System Tests

### Quick Start

```bash
# Run all system tests
./bin/system-test

# Run specific test file
./bin/system-test spec/system/document_upload_workflow_spec.rb

# Run with specific options
./bin/system-test --fail-fast
```

### Manual Selenium Management

```bash
# Start Selenium service
docker-compose up -d selenium

# Check Selenium status
curl http://localhost:4444/wd/hub/status

# View browser session (VNC)
open http://localhost:7900

# Stop Selenium
docker-compose stop selenium
```

## Configuration Details

### Capybara Configuration

The Capybara configuration (`spec/support/capybara.rb`) automatically detects whether tests are running in Docker and configures the appropriate driver:

- **In Docker**: Uses remote Selenium service
- **Local Development**: Uses local Chrome installation

All system tests automatically use Chrome headless by default. No need to specify `driven_by` in individual tests.

### System Test Helper

The `SystemTestHelper` module (`spec/support/system_test_helper.rb`) provides common functionality for all system tests:

- `login_as_user(user)`: Login helper
- `wait_for_ajax`: Wait for AJAX requests to complete
- `take_screenshot(name)`: Take a named screenshot
- `element_visible?(selector)`: Check element visibility
- `debug_here`: Pause execution for debugging

### Override Driver per Test

You can override the driver for specific tests:

```ruby
# Use rack_test (no JavaScript)
it "does something", driver: :rack_test do
  # test code
end

# Use chrome debug (visible browser)
it "needs debugging", driver: :chrome_debug do
  # test code
end

# Or mark entire context for debugging
context "complex feature", debug: true do
  # all tests here will use chrome_debug
end
```

### Environment Variables

- `DOCKER_CONTAINER=true`: Indicates tests are running in Docker
- `CAPYBARA_APP_HOST=web`: Tells Capybara where the Rails app is running
- `DEBUG=1`: Enable debug pauses in tests

### Debugging Tests

1. **View Live Browser**: Connect to http://localhost:7900 to see the browser in action
2. **Use `debug: true` metadata**: Automatically uses visible Chrome
3. **Use `debug_here` in tests**: Pauses execution when DEBUG=1
4. **Screenshots**: Failed tests automatically save screenshots to `tmp/screenshots/`

## Troubleshooting

### Common Issues

1. **Selenium not starting**: Check if port 4444 is already in use
2. **Tests can't connect**: Ensure all services are on the same Docker network
3. **Architecture mismatch**: The script automatically detects and uses the correct image

### Architecture-Specific Setup

For GitHub Actions or x86_64 systems:
```bash
docker-compose -f docker-compose.yml -f docker-compose.selenium-x86.yml up -d selenium
```

For ARM64 (Apple Silicon):
```bash
docker-compose up -d selenium  # Uses ARM64 image by default
```

## Benefits

1. **Isolation**: Chrome runs in its own container, avoiding profile conflicts
2. **Parallel Execution**: Can run multiple sessions simultaneously
3. **Debugging**: VNC access for visual debugging
4. **Cross-Platform**: Works on both ARM64 and x86_64 architectures
5. **CI/CD Ready**: Same setup works locally and in GitHub Actions