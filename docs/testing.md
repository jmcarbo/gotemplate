# Testing Guide

This document describes the testing strategy for the Go Template Repository.

## Overview

The template uses a comprehensive test suite implemented directly in GitHub Actions, providing:
- Parallel test execution
- Clear separation of concerns
- Platform-specific testing (Ubuntu and macOS)
- Easy debugging and maintenance

## Test Categories

### 1. Code Quality
Tests basic code quality requirements:
- Linting with golangci-lint
- Code formatting
- Build verification
- Unit tests

### 2. Template Instantiation
Tests project creation with various configurations:
- Basic project names
- Hyphenated names
- Complex module paths
- Cross-platform compatibility (Ubuntu/macOS)

### 3. Development Workflow
Tests the development experience:
- Dependency management
- Code formatting
- Linting
- Testing
- Building

### 4. Docker
Tests containerization:
- Docker image build
- Container execution
- Version flag verification

### 5. Template Sync
Tests the template update mechanism:
- Sync script functionality
- Git integration
- Dry-run mode

### 6. Version Management
Tests semantic versioning:
- Version display
- Version calculation

### 7. Pre-commit Hooks
Tests development tooling:
- Hook installation
- Commitizen integration

### 8. Integration
Full end-to-end testing:
- Complete project setup
- Development cycle
- API modifications
- Platform-specific adjustments

## Running Tests

### GitHub Actions
All tests run automatically on:
- Push to main/develop branches
- Pull requests
- Manual workflow dispatch

### Local Testing
For quick local validation:
```bash
# Run the local test script
./test/test_template.sh

# Or test manually
make setup-project PROJECT_NAME=test MODULE_PATH=github.com/test/test
make ci
```

## Test Implementation

Tests are implemented directly in `.github/workflows/test.yml` for:
- Better visibility
- Easier debugging
- No complex shell script dependencies
- Clear pass/fail status
- Parallel execution

## Platform Differences

### Ubuntu
- Full test suite including Docker
- Primary testing platform

### macOS
- Tests without Docker (not available in GitHub Actions)
- Validates cross-platform compatibility

## Debugging Failed Tests

1. Check the GitHub Actions run page
2. Each job shows clear pass/fail status
3. Failed steps show exact error messages
4. No need to dig through complex test logs

## Adding New Tests

To add a new test:

1. Add a new job in `.github/workflows/test.yml`
2. Define clear steps
3. Add to the `needs` array in `test-summary`
4. Update the summary check logic

Example:
```yaml
new-feature-test:
  name: New Feature Test
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v5
      with:
        go-version: ${{ env.GO_VERSION }}
    - name: Test New Feature
      run: |
        # Your test commands here
```

## Benefits of This Approach

1. **Simplicity**: Tests are just GitHub Actions steps
2. **Parallelization**: Tests run concurrently
3. **Visibility**: Clear status in GitHub UI
4. **Maintainability**: No complex test framework
5. **Debugging**: Direct error messages
6. **Flexibility**: Easy to add platform-specific logic

## Continuous Improvement

The test suite is designed to be:
- Extended as needed
- Adapted to new requirements
- Maintained with minimal effort
- Clear for contributors