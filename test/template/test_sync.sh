#!/bin/bash
# Test Template Sync Functionality
# Tests the template synchronization features

set -euo pipefail

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

# Setup a project and simulate updates
setup_sync_test() {
    create_test_project "syncproject" "github.com/testuser/syncproject"
    
    # Make the template repo a proper git remote
    run_in_test_project "git init"
    run_in_test_project "git add ."
    run_in_test_project "git commit -m 'Initial project commit'"
    run_in_test_project "echo 'file://$TEST_REPO_DIR' > .template-repo"
    
    # Update sync config to use local repo
    run_in_test_project "sed -i.bak 's|https://github.com/yourusername/gotemplaterepo|file://$TEST_REPO_DIR|g' .template-sync.yml"
}

# Test: Check for updates
test_check_updates() {
    setup_sync_test
    
    # Initially should be up to date
    run_in_test_project "./scripts/template-sync.sh --check || true"
    
    # Simulate template update
    simulate_template_update
    
    # Now should detect updates
    assert_command_fails "cd $TEST_PROJECT_DIR && ./scripts/template-sync.sh --check" "Should detect available updates"
}

# Test: Dry run sync
test_dry_run() {
    setup_sync_test
    simulate_template_update
    
    # Capture dry run output
    local output=$(run_in_test_project "./scripts/template-sync.sh --dry-run --verbose 2>&1")
    
    # Should mention changes but not apply them
    echo "$output" | grep -q "DRY RUN" || {
        log_error "Dry run should indicate it's not making changes"
        return 1
    }
    
    # Original files should be unchanged
    assert_command_fails "grep 'Updated' $TEST_PROJECT_DIR/README.md" "README should not be updated in dry run"
}

# Test: Overwrite files
test_overwrite_files() {
    setup_sync_test
    
    # Modify a file that should be overwritten
    run_in_test_project "echo 'custom content' > .gitignore"
    
    # Update template
    run_in_test_repo "echo '# Updated gitignore' >> .gitignore"
    run_in_test_repo "git add .gitignore && git commit -m 'Update gitignore'"
    
    # Run sync
    run_in_test_project "./scripts/template-sync.sh --force"
    
    # Check file was overwritten
    assert_file_contains "$TEST_PROJECT_DIR/.gitignore" "# Updated gitignore" "Gitignore should be overwritten"
}

# Test: Merge files
test_merge_files() {
    setup_sync_test
    
    # Modify Makefile (merge file)
    run_in_test_project "echo 'custom-target:' >> Makefile"
    
    # Update template Makefile
    run_in_test_repo "echo 'template-target:' >> Makefile"
    run_in_test_repo "git add Makefile && git commit -m 'Update Makefile'"
    
    # Run sync
    run_in_test_project "./scripts/template-sync.sh --force"
    
    # Should create merge file
    assert_file_exists "$TEST_PROJECT_DIR/Makefile.merge" "Merge file should be created"
    assert_file_contains "$TEST_PROJECT_DIR/Makefile.merge" "template-target:" "Merge file should contain template changes"
    assert_file_contains "$TEST_PROJECT_DIR/Makefile" "custom-target:" "Original file should retain custom content"
}

# Test: Create if missing
test_create_if_missing() {
    setup_sync_test
    
    # Remove a documentation file
    run_in_test_project "rm -f docs/examples.md"
    
    # Update template with new doc
    run_in_test_repo "echo '# New Example' > docs/new-example.md"
    run_in_test_repo "git add docs/new-example.md && git commit -m 'Add new example'"
    
    # Add to create_if_missing in sync config
    run_in_test_project "yq eval '.create_if_missing += [\"docs/new-example.md\"]' -i .template-sync.yml"
    
    # Run sync
    run_in_test_project "./scripts/template-sync.sh --force"
    
    # New file should be created
    assert_file_exists "$TEST_PROJECT_DIR/docs/new-example.md" "New doc should be created"
}

# Test: Exclude patterns
test_exclude_patterns() {
    setup_sync_test
    
    # Create custom application file
    run_in_test_project "mkdir -p internal/custom && echo 'custom code' > internal/custom/app.go"
    
    # Template tries to add file in internal
    run_in_test_repo "mkdir -p internal/custom && echo 'template code' > internal/custom/app.go"
    run_in_test_repo "git add internal/custom/app.go && git commit -m 'Add internal file'"
    
    # Run sync
    run_in_test_project "./scripts/template-sync.sh --force"
    
    # Custom file should be unchanged
    assert_file_contains "$TEST_PROJECT_DIR/internal/custom/app.go" "custom code" "Internal files should be excluded"
}

# Test: Backup functionality
test_backup() {
    setup_sync_test
    simulate_template_update
    
    # Get original content
    local original_readme=$(cat "$TEST_PROJECT_DIR/README.md")
    
    # Run sync
    run_in_test_project "./scripts/template-sync.sh --force"
    
    # Check backup was created
    assert_command_success "ls $TEST_PROJECT_DIR/.template-backup/*/README.md" "Backup should be created"
    
    # Backup should contain original content
    local backup_file=$(ls $TEST_PROJECT_DIR/.template-backup/*/README.md | head -1)
    assert_file_contains "$backup_file" "$original_readme" "Backup should contain original content"
}

# Test: Version tracking
test_version_tracking() {
    setup_sync_test
    
    # Check initial version
    local initial_version=$(cat "$TEST_PROJECT_DIR/.template-version")
    
    # Update template with tag
    run_in_test_repo "git tag v1.0.0"
    
    # Run sync
    run_in_test_project "./scripts/template-sync.sh --force"
    
    # Version should be updated
    local new_version=$(cat "$TEST_PROJECT_DIR/.template-version")
    assert_equals "v1.0.0" "$new_version" "Template version should be updated"
}

# Test: Pre and post sync hooks
test_sync_hooks() {
    setup_sync_test
    
    # Add hooks to config
    cat >> "$TEST_PROJECT_DIR/.template-sync.yml" << EOF
hooks:
  pre_sync:
    - "touch .pre-sync-marker"
  post_sync:
    - "touch .post-sync-marker"
EOF
    
    simulate_template_update
    
    # Run sync
    run_in_test_project "./scripts/template-sync.sh --force"
    
    # Check hooks were executed
    assert_file_exists "$TEST_PROJECT_DIR/.pre-sync-marker" "Pre-sync hook should run"
    assert_file_exists "$TEST_PROJECT_DIR/.post-sync-marker" "Post-sync hook should run"
}

# Test: Handle missing yq
test_missing_yq() {
    setup_sync_test
    
    # Temporarily rename yq if it exists
    if command -v yq &> /dev/null; then
        run_in_test_project "mv $(which yq) $(which yq).bak 2>/dev/null || true"
    fi
    
    # Should handle missing yq gracefully
    local output=$(run_in_test_project "./scripts/template-sync.sh --check 2>&1 || true")
    echo "$output" | grep -q "yq is required" || {
        log_error "Should detect missing yq"
        return 1
    }
    
    # Restore yq
    if [[ -f "$(which yq).bak" ]]; then
        run_in_test_project "mv $(which yq).bak $(which yq) 2>/dev/null || true"
    fi
}

# Test: Invalid configuration
test_invalid_config() {
    setup_sync_test
    
    # Break the config file
    run_in_test_project "echo 'invalid: yaml: content:' > .template-sync.yml"
    
    # Should fail gracefully
    assert_command_fails "cd $TEST_PROJECT_DIR && ./scripts/template-sync.sh --check" "Should fail with invalid config"
}

# Main test execution
main() {
    log_info "Starting Template Sync Tests"
    
    setup_test_env
    
    run_test "Check for updates" test_check_updates
    run_test "Dry run sync" test_dry_run
    run_test "Overwrite files" test_overwrite_files
    run_test "Merge files" test_merge_files
    run_test "Create if missing" test_create_if_missing
    run_test "Exclude patterns" test_exclude_patterns
    run_test "Backup functionality" test_backup
    run_test "Version tracking" test_version_tracking
    run_test "Sync hooks" test_sync_hooks
    run_test "Handle missing yq" test_missing_yq
    run_test "Invalid configuration" test_invalid_config
    
    print_test_summary
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi