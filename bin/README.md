# Development Scripts

This directory contains automation scripts to streamline development and ensure CI/CD compatibility.

## 🚀 Quick Start

```bash
# First time setup
./bin/setup-dev

# Before committing code
./bin/quick-check --fix

# Full CI simulation
./bin/pre-ci --fix
```

## 📋 Available Scripts

### `./bin/setup-dev`
**Complete development environment setup**
- Builds Docker images and starts services
- Installs dependencies (Ruby + JavaScript)
- Creates and seeds databases
- Sets up parallel test databases
- Builds assets
- Runs health checks

### `./bin/pre-ci` 
**Complete CI/CD pipeline simulation**
- **Options**: `--fix`, `--fast`, `--verbose`
- Runs security scans (Brakeman, Bundle Audit, Bun Audit)
- Executes linting (RuboCop, ESLint, Stylelint)
- Sets up test environment
- Runs parallel tests (main app + engine)
- Executes system tests with Selenium
- Provides detailed success/failure reports

### `./bin/quick-check`
**Fast pre-commit validation**
- **Options**: `--fix`
- Style checking (RuboCop, ESLint, Stylelint)
- Quick test sample
- Auto-fixes common issues
- Perfect for rapid development feedback

### `./bin/ci-doctor`
**Environment diagnostic and troubleshooting**
- Checks Docker setup and services
- Validates configuration files
- Tests database connections
- Identifies common issues (binding.pry, focused specs)
- Provides fix recommendations
- Shows performance metrics

## 🔧 Auto-Fix Capabilities

When using `--fix` flag, scripts can automatically resolve:

- **RuboCop**: Style violations and layout issues
- **ESLint**: JavaScript code style and best practices  
- **Stylelint**: CSS formatting and conventions
- **Bundle Lock**: Missing x86_64-linux platform for CI
- **Dependencies**: Security vulnerabilities via updates

## 🎯 Usage Patterns

### Development Workflow
```bash
# 1. Start developing
./bin/quick-check --fix

# 2. Before committing
./bin/quick-check --fix

# 3. Before pushing
./bin/pre-ci --fast --fix
```

### CI Troubleshooting
```bash
# Diagnose environment
./bin/ci-doctor

# Full simulation
./bin/pre-ci --verbose

# Focus on specific issues
./bin/pre-ci --fast --fix
```

### Performance Testing
```bash
# Fast feedback loop
./bin/quick-check

# Skip slower system tests
./bin/pre-ci --fast

# Full CI experience
./bin/pre-ci
```

## 🏗️ Architecture

All scripts use:
- **Docker Compose** for consistent environment
- **Parallel testing** with 4 processors
- **Color-coded output** for clear feedback
- **Detailed error reporting** with fix suggestions
- **Exit codes** for automation compatibility

## 🔍 What Each Script Validates

### Security Scans
- Ruby vulnerabilities (Brakeman + Bundle Audit)
- JavaScript dependencies (Bun Audit)
- Static code analysis

### Code Quality
- Ruby style (RuboCop)
- JavaScript linting (ESLint)
- CSS standards (Stylelint)

### Testing
- Unit tests (models, controllers, services)
- Integration tests (policies, components)
- System tests (browser automation with Selenium)
- Engine tests (Immo::Promo module)

### Environment
- Docker services health
- Database connectivity
- Platform compatibility (x86_64-linux for CI)
- Asset compilation

## 💡 Tips

- Use `./bin/quick-check --fix` during development for fast feedback
- Run `./bin/pre-ci --fix` before creating pull requests
- Use `./bin/ci-doctor` when encountering mysterious CI failures
- Set up IDE integration to run `./bin/quick-check` on save