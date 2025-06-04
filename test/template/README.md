# Template Tests

This directory contains comprehensive tests for the Go template repository functionality.

## Overview

These tests ensure that:
1. The template can be successfully instantiated for new projects
2. Template synchronization works correctly
3. All build and development commands function properly
4. Version management and semantic versioning work as expected

## Test Structure

```
test/template/
├── test_framework.sh      # Common test utilities and assertions
├── test_instantiation.sh  # Tests for creating new projects from template
├── test_sync.sh          # Tests for template synchronization
├── test_build_dev.sh     # Tests for build and development commands
├── test_version.sh       # Tests for version management
├── run_all_tests.sh      # Main test runner
└── README.md             # This file
```

## Running Tests

### Run All Tests
```bash
# From project root
make test-template

# With verbose output
make test-template-verbose

# Or directly
./test/template/run_all_tests.sh
```

### Run Individual Test Suites
```bash
# Test template instantiation
make test-instantiation

# Test template sync
make test-sync

# Test build commands
make test-build-dev

# Test version management
make test-version
```

### Command Line Options
```bash
# Verbose output
./test/template/run_all_tests.sh --verbose

# Stop on first failure
./test/template/run_all_tests.sh --fail-fast

# Both options
./test/template/run_all_tests.sh --verbose --fail-fast
```

## Test Environment

Tests run in isolated temporary directories to avoid polluting the repository:
- Default location: `/tmp/gotemplate-tests-$$`
- Automatically cleaned up after tests
- Each test suite gets a fresh environment

## Test Coverage

### Template Instantiation Tests
- Basic project setup with custom name and module path
- Special characters in project names
- Go build verification after setup
- Pre-commit hooks installation
- Environment file setup
- Documentation and command preservation
- Make targets functionality
- Version file initialization

### Template Sync Tests
- Checking for updates
- Dry-run mode
- File overwriting behavior
- Merge file creation
- Create-if-missing functionality
- Exclude patterns
- Backup functionality
- Version tracking
- Pre/post sync hooks
- Error handling

### Build and Development Tests
- `make build` - Binary compilation
- `make test` - Test execution
- `make lint` - Code linting
- `make fmt` - Code formatting
- `make clean` - Cleanup
- `make deps` - Dependency management
- `make docker-build` - Docker image creation
- CI/CD pipeline commands

### Version Management Tests
- Initial version setup
- Conventional commit validation
- Semantic version calculation
- Release commands
- Changelog generation
- Breaking change detection
- Pre-commit hooks for commit messages

## CI/CD Integration

The template includes a GitHub Action (`.github/workflows/template-tests.yml`) that:
- Runs on push and pull requests
- Tests on multiple operating systems (Ubuntu, macOS)
- Runs all test suites
- Tests Docker builds
- Matrix testing for different project configurations

## Dependencies

Required tools:
- `bash` (4.0+)
- `git`
- `make`
- `go` (1.24+)
- `docker` (for Docker tests)

Optional tools (some tests will skip if not present):
- `yq` - YAML parsing
- `git-semver` - Version calculation
- `git-cliff` - Changelog generation
- `golangci-lint` - Go linting

## Writing New Tests

To add new tests:

1. Create a new test file following the naming pattern `test_*.sh`
2. Source the test framework:
   ```bash
   source "$SCRIPT_DIR/test_framework.sh"
   ```
3. Use provided assertion functions:
   ```bash
   assert_equals "expected" "$actual" "Error message"
   assert_file_exists "$file" "File should exist"
   assert_command_success "make build" "Build should succeed"
   ```
4. Add test to `run_all_tests.sh`

## Troubleshooting

### Tests Failing Locally
1. Ensure all dependencies are installed
2. Check for sufficient disk space in `/tmp`
3. Run with `--verbose` for detailed output
4. Check test logs in `/tmp/gotemplate-tests-*/`

### CI Tests Failing
1. Check the test artifacts uploaded on failure
2. Verify OS-specific commands work on all platforms
3. Ensure all required tools are installed in CI

### Permission Issues
```bash
# Make all test scripts executable
chmod +x test/template/*.sh
```

## Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Always clean up test artifacts
3. **Idempotency**: Tests should produce same results on repeated runs
4. **Speed**: Keep tests fast by avoiding unnecessary operations
5. **Clarity**: Use descriptive test names and error messages

## Contributing

When modifying the template:
1. Run all tests before committing
2. Add tests for new functionality
3. Update this README if adding new test suites
4. Ensure tests work on both Linux and macOS