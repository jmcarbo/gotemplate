#!/bin/bash
# Test Build and Development Commands
# Tests make targets and development workflow

set -euo pipefail

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

# Setup a minimal Go project structure
setup_build_test() {
    create_test_project "buildproject" "github.com/testuser/buildproject"
    
    # Create minimal main.go
    cat > "$TEST_PROJECT_DIR/cmd/api/main.go" << 'EOF'
package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    fmt.Println("Starting server...")
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, World!")
    })
    log.Fatal(http.ListenAndServe(":8080", nil))
}
EOF

    # Create a simple test file
    mkdir -p "$TEST_PROJECT_DIR/internal/domain/entities"
    cat > "$TEST_PROJECT_DIR/internal/domain/entities/example.go" << 'EOF'
package entities

type Example struct {
    ID   string
    Name string
}

func NewExample(id, name string) *Example {
    return &Example{ID: id, Name: name}
}
EOF

    cat > "$TEST_PROJECT_DIR/internal/domain/entities/example_test.go" << 'EOF'
package entities

import "testing"

func TestNewExample(t *testing.T) {
    e := NewExample("1", "test")
    if e.ID != "1" {
        t.Errorf("expected ID 1, got %s", e.ID)
    }
}
EOF

    # Initialize go module properly
    run_in_test_project "go mod tidy"
}

# Test: Make build
test_make_build() {
    setup_build_test
    
    # Run build
    run_in_test_project "make build"
    
    # Check binary was created
    assert_file_exists "$TEST_PROJECT_DIR/bin/buildproject" "Binary should be created"
    
    # Binary should be executable
    assert_command_success "test -x $TEST_PROJECT_DIR/bin/buildproject" "Binary should be executable"
}

# Test: Make test
test_make_test() {
    setup_build_test
    
    # Run tests
    assert_command_success "cd $TEST_PROJECT_DIR && make test" "Tests should pass"
    
    # Check coverage file was created
    assert_file_exists "$TEST_PROJECT_DIR/coverage.txt" "Coverage file should be created"
}

# Test: Make lint
test_make_lint() {
    setup_build_test
    
    # Install golangci-lint first
    run_in_test_project "make install-tools || true"
    
    # Run linter
    assert_command_success "cd $TEST_PROJECT_DIR && make lint" "Linting should pass"
}

# Test: Make fmt
test_make_fmt() {
    setup_build_test
    
    # Mess up formatting
    cat >> "$TEST_PROJECT_DIR/cmd/api/main.go" << 'EOF'

func   badlyFormatted()   {
fmt.Println("bad"   )
}
EOF

    # Run formatter
    run_in_test_project "make fmt"
    
    # Check formatting was fixed
    assert_command_success "cd $TEST_PROJECT_DIR && gofmt -l cmd/api/main.go | grep -q '^$'" "Code should be formatted"
}

# Test: Make clean
test_make_clean() {
    setup_build_test
    
    # Build first
    run_in_test_project "make build"
    run_in_test_project "make test"
    
    # Check files exist
    assert_file_exists "$TEST_PROJECT_DIR/bin/buildproject" "Binary should exist before clean"
    assert_file_exists "$TEST_PROJECT_DIR/coverage.txt" "Coverage should exist before clean"
    
    # Clean
    run_in_test_project "make clean"
    
    # Check files are removed
    assert_command_fails "test -f $TEST_PROJECT_DIR/bin/buildproject" "Binary should be removed"
    assert_command_fails "test -f $TEST_PROJECT_DIR/coverage.txt" "Coverage should be removed"
}

# Test: Make deps
test_make_deps() {
    setup_build_test
    
    # Add a dependency
    run_in_test_project "go get github.com/gorilla/mux"
    
    # Run deps
    assert_command_success "cd $TEST_PROJECT_DIR && make deps" "Deps should download successfully"
}

# Test: Make tidy
test_make_tidy() {
    setup_build_test
    
    # Add unused dependency
    run_in_test_project "go get github.com/stretchr/testify"
    
    # Run tidy
    run_in_test_project "make tidy"
    
    # Check go.mod is clean
    assert_command_success "cd $TEST_PROJECT_DIR && go mod verify" "Go mod should be tidy"
}

# Test: Make docker-build
test_make_docker_build() {
    setup_build_test
    
    # Skip if docker not available
    if ! command -v docker &> /dev/null; then
        log_warn "Docker not available, skipping docker-build test"
        return 0
    fi
    
    # Try to build docker image
    assert_command_success "cd $TEST_PROJECT_DIR && make docker-build" "Docker build should succeed"
}

# Test: Make help
test_make_help() {
    setup_build_test
    
    # Run help
    local output=$(run_in_test_project "make help")
    
    # Check help output contains expected sections
    echo "$output" | grep -q "Usage:" || {
        log_error "Help should show usage"
        return 1
    }
    
    echo "$output" | grep -q "Build:" || {
        log_error "Help should show build targets"
        return 1
    }
    
    echo "$output" | grep -q "Test:" || {
        log_error "Help should show test targets"
        return 1
    }
}

# Test: Make ci
test_make_ci() {
    setup_build_test
    
    # Run CI pipeline
    assert_command_success "cd $TEST_PROJECT_DIR && make ci" "CI pipeline should pass"
}

# Test: Make pre-commit
test_make_precommit() {
    setup_build_test
    
    # Initialize git repo
    run_in_test_project "git init && git add . && git commit -m 'Initial commit' || true"
    
    # Run pre-commit checks
    assert_command_success "cd $TEST_PROJECT_DIR && make pre-commit" "Pre-commit checks should pass"
}

# Test: Make test-coverage
test_make_coverage() {
    setup_build_test
    
    # Run coverage
    run_in_test_project "make test-coverage"
    
    # Check coverage report was created
    assert_file_exists "$TEST_PROJECT_DIR/coverage.html" "Coverage HTML report should be created"
}

# Test: Make benchmark
test_make_benchmark() {
    setup_build_test
    
    # Add a benchmark
    cat >> "$TEST_PROJECT_DIR/internal/domain/entities/example_test.go" << 'EOF'

func BenchmarkNewExample(b *testing.B) {
    for i := 0; i < b.N; i++ {
        NewExample("1", "test")
    }
}
EOF

    # Run benchmarks
    assert_command_success "cd $TEST_PROJECT_DIR && make benchmark" "Benchmarks should run"
}

# Main test execution
main() {
    log_info "Starting Build and Development Tests"
    
    setup_test_env
    
    run_test "Make build" test_make_build
    run_test "Make test" test_make_test
    run_test "Make lint" test_make_lint
    run_test "Make fmt" test_make_fmt
    run_test "Make clean" test_make_clean
    run_test "Make deps" test_make_deps
    run_test "Make tidy" test_make_tidy
    run_test "Make docker-build" test_make_docker_build
    run_test "Make help" test_make_help
    run_test "Make ci" test_make_ci
    run_test "Make pre-commit" test_make_precommit
    run_test "Make test-coverage" test_make_coverage
    run_test "Make benchmark" test_make_benchmark
    
    print_test_summary
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi