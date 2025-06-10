# JavaScript Runtime - Bun

## Overview

Docusphere uses **Bun** as its JavaScript runtime instead of Node.js. Bun is a fast all-in-one JavaScript runtime that includes a bundler, test runner, and package manager, providing significant performance improvements over traditional Node.js workflows.

## Why Bun?

1. **Performance**: Bun is significantly faster than Node.js for both runtime execution and package installation
2. **Built-in Tools**: Includes bundler, test runner, and package manager without additional dependencies
3. **Native TypeScript Support**: Can run TypeScript files directly without transpilation
4. **Compatibility**: Drop-in replacement for Node.js with npm package compatibility

## Usage in Docusphere

### Package Management

```bash
# Install dependencies
bun install

# Add a new dependency
bun add package-name

# Add a dev dependency
bun add -d package-name

# Update dependencies
bun update
```

### Build Scripts

The `package.json` defines several Bun-powered scripts:

```json
{
  "scripts": {
    "build": "bun build app/javascript/application.js --outdir=app/assets/builds --minify",
    "build:css": "tailwindcss -i ./app/assets/stylesheets/application.css -o ./app/assets/builds/application.css",
    "build:css:watch": "tailwindcss -i ./app/assets/stylesheets/application.css -o ./app/assets/builds/application.css --watch",
    "test": "bun test spec/javascript",
    "test:watch": "bun test spec/javascript --watch"
  }
}
```

### JavaScript Testing

Bun includes a built-in test runner that's used for testing Stimulus controllers:

```javascript
// spec/javascript/controllers/widget_loader_controller_spec.js
import { describe, test, expect, beforeEach, mock } from 'bun:test'
import { Application } from '@hotwired/stimulus'
import WidgetLoaderController from '../../../app/javascript/controllers/widget_loader_controller'
import '../setup' // JSDOM setup

describe('WidgetLoaderController', () => {
  test('loads content on connect', async () => {
    // Test implementation
  })
})
```

### Test Setup

The `spec/javascript/setup.js` file configures JSDOM for testing:

```javascript
import { JSDOM } from 'jsdom'

const jsdom = new JSDOM('<!doctype html><html><body></body></html>', {
  url: 'http://localhost:3000',
  pretendToBeVisual: true,
  resources: 'usable'
})

global.window = jsdom.window
global.document = window.document
// ... other globals
```

## Docker Integration

Both development and production Dockerfiles are configured to use Bun:

### Development (Dockerfile.dev)
```dockerfile
# Install Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

# Install packages with Bun
RUN bun install
```

### Production (Dockerfile)
```dockerfile
# Install Bun in build stage
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

# Install with frozen lockfile for reproducible builds
RUN bun install --frozen-lockfile

# Build assets with Bun
RUN bun run build && bun run build:css
```

## Development Workflow

1. **Running Tests**:
   ```bash
   # Inside Docker
   docker-compose run --rm web bun test spec/javascript
   
   # With the unified test script
   ./bin/test units  # Includes JavaScript tests
   ```

2. **Building Assets**:
   ```bash
   # Development build
   docker-compose run --rm web bun run build
   
   # Watch mode for CSS
   docker-compose run --rm web bun run build:css:watch
   ```

3. **Adding Dependencies**:
   ```bash
   # Add a new package
   docker-compose run --rm web bun add stimulus-use
   
   # Add dev dependency
   docker-compose run --rm web bun add -d @types/stimulus
   ```

## Lock File

Bun uses `bun.lock` (previously `bun.lockb`) to lock dependency versions. This file is:
- Committed to version control
- Used with `--frozen-lockfile` in production builds
- Automatically updated when running `bun install` or `bun add`

## Migration from Node.js/Yarn

If migrating from an existing Node.js setup:

1. Delete `node_modules`, `yarn.lock`, `package-lock.json`
2. Run `bun install` to generate `bun.lock`
3. Update scripts in `package.json` to use `bun` commands
4. Update CI/CD pipelines to install and use Bun

## Performance Benefits

Typical improvements seen with Bun:

- **Package Installation**: 10-100x faster than npm/yarn
- **Script Execution**: 2-4x faster startup time
- **Test Running**: 3-5x faster test execution
- **Build Times**: 20-50% reduction in asset compilation

## Troubleshooting

### Common Issues

1. **Binary Compatibility**: Some native Node.js modules may need recompilation
   ```bash
   bun install --force
   ```

2. **Test Timeouts**: Bun's test runner is faster, adjust timeouts if needed
   ```javascript
   test('async test', async () => {
     // test code
   }, 10000) // 10 second timeout
   ```

3. **Module Resolution**: Bun follows Node.js resolution but is stricter
   - Ensure all imports have proper extensions
   - Use `index.js` explicitly when needed

## Resources

- [Bun Documentation](https://bun.sh/docs)
- [Bun GitHub](https://github.com/oven-sh/bun)
- [Migrating from Node.js](https://bun.sh/docs/migrate)