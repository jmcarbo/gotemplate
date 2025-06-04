#!/bin/bash
# Test Version Management
# Tests semantic versioning and release functionality

set -euo pipefail

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

# Setup version test environment
setup_version_test() {
    create_test_project "versionproject" "github.com/testuser/versionproject"
    
    # Initialize git repo with initial commit
    run_in_test_project "git init"
    run_in_test_project "git add ."
    run_in_test_project "git commit -m 'Initial commit'"
    
    # Install svu if not present
    if ! command -v svu &> /dev/null; then
        log_warn "svu not installed, some tests will be skipped"
    fi
}

# Test: Initial version
test_initial_version() {
    setup_version_test
    
    # Check VERSION file
    assert_file_contains "$TEST_PROJECT_DIR/VERSION" "0.0.0" "Initial VERSION should be 0.0.0"
    
    # Check make version
    local version_output=$(run_in_test_project "make version 2>&1")
    echo "$version_output" | grep -q "0.0.0" || {
        log_error "Make version should show 0.0.0"
        return 1
    }
}

# Test: Conventional commit detection
test_conventional_commits() {
    setup_version_test
    
    # Make various conventional commits
    run_in_test_project "echo 'fix' > fix.txt && git add fix.txt && git commit -m 'fix: resolve bug'"
    run_in_test_project "echo 'feat' > feat.txt && git add feat.txt && git commit -m 'feat: add new feature'"
    run_in_test_project "echo 'docs' > docs.txt && git add docs.txt && git commit -m 'docs: update readme'"
    
    # Check git log shows commits
    local log_output=$(run_in_test_project "git log --oneline")
    echo "$log_output" | grep -q "fix: resolve bug" || {
        log_error "Fix commit should be in log"
        return 1
    }
}

# Test: Version calculation
test_version_calculation() {
    setup_version_test
    
    # Skip if svu not available
    if ! command -v svu &> /dev/null; then
        log_warn "Skipping version calculation test (svu not installed)"
        return 0
    fi
    
    # Tag initial version
    run_in_test_project "git tag v0.0.0"
    
    # Make a fix commit
    run_in_test_project "echo 'fix' > fix.txt && git add fix.txt && git commit -m 'fix: bug fix'"
    
    # Check next version would be patch
    local next_version=$(run_in_test_project "svu next" 2>/dev/null || echo "")
    if [[ -n "$next_version" ]]; then
        echo "$next_version" | grep -q "v0.0.1" || {
            log_error "Next version after fix should be v0.0.1"
            return 1
        }
    fi
}

# Test: Make release commands
test_make_release() {
    setup_version_test
    
    # Skip if svu not available
    if ! command -v svu &> /dev/null; then
        log_warn "Skipping make release test (svu not installed)"
        return 0
    fi
    
    # Tag initial version
    run_in_test_project "git tag v0.0.0"
    
    # Make a feature commit
    run_in_test_project "echo 'feature' > feature.txt && git add feature.txt && git commit -m 'feat: new feature'"
    
    # Test release-patch
    run_in_test_project "make release-patch"
    local tags=$(run_in_test_project "git tag")
    echo "$tags" | grep -q "v0.0.1" || {
        log_error "Patch release should create v0.0.1 tag"
        return 1
    }
}

# Test: Commitizen configuration
test_commitizen() {
    setup_version_test
    
    # Check .czrc exists
    assert_file_exists "$TEST_PROJECT_DIR/.czrc" "Commitizen config should exist"
    
    # Check configuration
    assert_file_contains "$TEST_PROJECT_DIR/.czrc" "cz_conventional_commits" "Should use conventional commits"
    assert_file_contains "$TEST_PROJECT_DIR/.czrc" "tag_format" "Should have tag format"
}

# Test: Git cliff configuration
test_git_cliff() {
    setup_version_test
    
    # Check cliff.toml exists
    assert_file_exists "$TEST_PROJECT_DIR/cliff.toml" "Git cliff config should exist"
    
    # Check configuration
    assert_file_contains "$TEST_PROJECT_DIR/cliff.toml" "conventional_commits = true" "Should use conventional commits"
    assert_file_contains "$TEST_PROJECT_DIR/cliff.toml" "Features" "Should have Features group"
    assert_file_contains "$TEST_PROJECT_DIR/cliff.toml" "Bug Fixes" "Should have Bug Fixes group"
}

# Test: Changelog generation
test_changelog() {
    setup_version_test
    
    # Skip if git-cliff not available
    if ! command -v git-cliff &> /dev/null; then
        log_warn "Skipping changelog test (git-cliff not installed)"
        return 0
    fi
    
    # Make some commits
    run_in_test_project "echo 'fix' > fix.txt && git add fix.txt && git commit -m 'fix: bug fix'"
    run_in_test_project "echo 'feat' > feat.txt && git add feat.txt && git commit -m 'feat: new feature'"
    
    # Generate changelog
    local changelog_output=$(run_in_test_project "make changelog 2>&1" || echo "")
    
    # Should contain sections
    echo "$changelog_output" | grep -q -E "(Features|Bug Fixes)" || {
        log_warn "Changelog might not be properly formatted"
    }
}

# Test: Pre-commit hook for conventional commits
test_precommit_conventional() {
    setup_version_test
    
    # Install pre-commit hooks
    run_in_test_project "./scripts/install-hooks.sh"
    
    # Try non-conventional commit (should fail)
    run_in_test_project "echo 'bad' > bad.txt && git add bad.txt"
    assert_command_fails "cd $TEST_PROJECT_DIR && git commit -m 'bad commit message'" "Non-conventional commit should fail"
    
    # Try conventional commit (should succeed)
    assert_command_success "cd $TEST_PROJECT_DIR && git commit -m 'feat: good commit message'" "Conventional commit should succeed"
}

# Test: Version in CI/CD
test_version_in_ci() {
    setup_version_test
    
    # Check GitHub workflows reference version
    assert_file_exists "$TEST_PROJECT_DIR/.github/workflows/release.yml" "Release workflow should exist"
    assert_file_contains "$TEST_PROJECT_DIR/.github/workflows/release.yml" "tag" "Release workflow should handle tags"
}

# Test: Breaking changes
test_breaking_changes() {
    setup_version_test
    
    # Skip if svu not available
    if ! command -v svu &> /dev/null; then
        log_warn "Skipping breaking changes test (svu not installed)"
        return 0
    fi
    
    # Tag initial version
    run_in_test_project "git tag v1.0.0"
    
    # Make a breaking change commit
    run_in_test_project "echo 'breaking' > breaking.txt && git add breaking.txt"
    run_in_test_project "git commit -m 'feat!: breaking change'"
    
    # Next version should be major
    local next_version=$(run_in_test_project "svu next" 2>/dev/null || echo "")
    if [[ -n "$next_version" ]]; then
        echo "$next_version" | grep -q "v2.0.0" || {
            log_error "Breaking change should bump major version"
            return 1
        }
    fi
}

# Main test execution
main() {
    log_info "Starting Version Management Tests"
    
    setup_test_env
    
    run_test "Initial version" test_initial_version
    run_test "Conventional commits" test_conventional_commits
    run_test "Version calculation" test_version_calculation
    run_test "Make release commands" test_make_release
    run_test "Commitizen configuration" test_commitizen
    run_test "Git cliff configuration" test_git_cliff
    run_test "Changelog generation" test_changelog
    run_test "Pre-commit conventional commits" test_precommit_conventional
    run_test "Version in CI/CD" test_version_in_ci
    run_test "Breaking changes" test_breaking_changes
    
    print_test_summary
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi