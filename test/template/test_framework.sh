#!/bin/bash
# Template Test Framework
# Provides utilities for testing template functionality in isolated environments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test environment setup
export TEST_DIR="${TEST_DIR:-/tmp/gotemplate-tests-$$}"
export TEST_REPO_DIR="${TEST_DIR}/template-repo"
export TEST_PROJECT_DIR="${TEST_DIR}/test-project"
export TEMPLATE_URL="${TEMPLATE_URL:-https://github.com/jmcarbo/gotemplate}"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    if [[ "$expected" != "$actual" ]]; then
        log_error "$message: expected '$expected', got '$actual'"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    if [[ ! -f "$file" ]]; then
        log_error "$message: $file"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist}"
    
    if [[ ! -d "$dir" ]]; then
        log_error "$message: $dir"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="${3:-File should contain pattern}"
    
    if ! grep -q "$pattern" "$file"; then
        log_error "$message: $pattern not found in $file"
        return 1
    fi
}

assert_command_success() {
    local command="$1"
    local message="${2:-Command should succeed}"
    
    if ! eval "$command" > /dev/null 2>&1; then
        log_error "$message: $command"
        return 1
    fi
}

assert_command_fails() {
    local command="$1"
    local message="${2:-Command should fail}"
    
    if eval "$command" > /dev/null 2>&1; then
        log_error "$message: $command"
        return 1
    fi
}

# Test environment management
setup_test_env() {
    log_info "Setting up test environment in $TEST_DIR"
    
    # Configure git if not already configured
    if ! git config --global user.email > /dev/null 2>&1; then
        git config --global user.email "test@example.com"
        git config --global user.name "Test User"
    fi
    
    # Clean up any existing test directory
    cleanup_test_env
    
    # Create test directories
    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_REPO_DIR"
    mkdir -p "$TEST_PROJECT_DIR"
    
    # Copy template repository to test location
    if [[ -d "." ]]; then
        log_info "Copying local template repository..."
        cp -r . "$TEST_REPO_DIR"
        # Clean up any git info to simulate fresh clone
        rm -rf "$TEST_REPO_DIR/.git"
        (cd "$TEST_REPO_DIR" && git init && git add . && git commit -m "Initial commit")
    else
        log_info "Cloning template repository..."
        git clone "$TEMPLATE_URL" "$TEST_REPO_DIR"
    fi
}

cleanup_test_env() {
    if [[ -d "$TEST_DIR" ]]; then
        log_info "Cleaning up test environment"
        rm -rf "$TEST_DIR"
    fi
}

# Run a command in the test repository
run_in_test_repo() {
    (cd "$TEST_REPO_DIR" && eval "$@")
}

# Run a command in the test project
run_in_test_project() {
    (cd "$TEST_PROJECT_DIR" && eval "$@")
}

# Create a test project from template
create_test_project() {
    local project_name="${1:-testproject}"
    local module_path="${2:-github.com/testuser/testproject}"
    
    log_info "Creating test project: $project_name"
    
    # Copy template to project directory
    cp -r "$TEST_REPO_DIR"/* "$TEST_PROJECT_DIR"
    cp -r "$TEST_REPO_DIR"/.* "$TEST_PROJECT_DIR" 2>/dev/null || true
    
    # Run setup
    run_in_test_project "make setup-project PROJECT_NAME=$project_name MODULE_PATH=$module_path"
}

# Simulate template updates
simulate_template_update() {
    log_info "Simulating template update"
    
    run_in_test_repo "echo '# Updated' >> README.md"
    run_in_test_repo "echo 'updated: true' >> .golangci.yml"
    run_in_test_repo "git add -A && git commit -m 'feat: template updates'"
    run_in_test_repo "git tag v0.1.0"
}

# Test result tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    log_test "Running: $test_name"
    
    if $test_function; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_info "✓ $test_name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "✗ $test_name"
    fi
}

print_test_summary() {
    echo
    echo "========================================="
    echo "Test Summary:"
    echo "  Total:  $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "========================================="
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        return 1
    fi
}

# Trap to ensure cleanup on exit
trap cleanup_test_env EXIT