#!/bin/bash
# Run All Template Tests
# Main test runner that executes all test suites

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework for summary functions
source "$SCRIPT_DIR/test_framework.sh"

# Test configuration
VERBOSE="${VERBOSE:-false}"
FAIL_FAST="${FAIL_FAST:-false}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            export VERBOSE
            shift
            ;;
        --fail-fast|-f)
            FAIL_FAST=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose     Show detailed test output"
            echo "  -f, --fail-fast   Stop on first test failure"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
START_TIME=$(date +%s)

# Print header
echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Go Template Repository Test Suite${NC}"
echo -e "${CYAN}================================${NC}"
echo

# Function to run a test suite
run_test_suite() {
    local suite_name="$1"
    local suite_script="$2"
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo -e "${BLUE}Running $suite_name...${NC}"
    
    if [[ "$VERBOSE" == "true" ]]; then
        if bash "$suite_script"; then
            PASSED_SUITES=$((PASSED_SUITES + 1))
            echo -e "${GREEN}✓ $suite_name passed${NC}"
        else
            FAILED_SUITES=$((FAILED_SUITES + 1))
            echo -e "${RED}✗ $suite_name failed${NC}"
            if [[ "$FAIL_FAST" == "true" ]]; then
                echo -e "${RED}Stopping due to --fail-fast${NC}"
                exit 1
            fi
        fi
    else
        # Capture output when not verbose
        local output_file="/tmp/test_output_$$_$(basename "$suite_script").log"
        if bash "$suite_script" > "$output_file" 2>&1; then
            PASSED_SUITES=$((PASSED_SUITES + 1))
            echo -e "${GREEN}✓ $suite_name passed${NC}"
            rm -f "$output_file"
        else
            FAILED_SUITES=$((FAILED_SUITES + 1))
            echo -e "${RED}✗ $suite_name failed${NC}"
            echo -e "${YELLOW}  See output below:${NC}"
            cat "$output_file"
            rm -f "$output_file"
            if [[ "$FAIL_FAST" == "true" ]]; then
                echo -e "${RED}Stopping due to --fail-fast${NC}"
                exit 1
            fi
        fi
    fi
    
    echo
}

# Check dependencies
check_dependencies() {
    log_info "Checking test dependencies..."
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in git make go docker; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for optional but recommended tools
    local optional_deps=()
    for cmd in yq git-semver git-cliff; do
        if ! command -v "$cmd" &> /dev/null; then
            optional_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install these tools before running tests."
        exit 1
    fi
    
    if [[ ${#optional_deps[@]} -gt 0 ]]; then
        log_warn "Missing optional dependencies: ${optional_deps[*]}"
        echo "Some tests may be skipped."
    fi
    
    echo
}

# Main execution
main() {
    check_dependencies
    
    # Run all test suites
    run_test_suite "Template Instantiation Tests" "$SCRIPT_DIR/test_instantiation.sh"
    run_test_suite "Template Sync Tests" "$SCRIPT_DIR/test_sync.sh"
    run_test_suite "Build and Development Tests" "$SCRIPT_DIR/test_build_dev.sh"
    run_test_suite "Version Management Tests" "$SCRIPT_DIR/test_version.sh"
    
    # Calculate execution time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # Print final summary
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}Final Test Summary${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
    echo "Test Suites Run: $TOTAL_SUITES"
    echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"
    echo -e "${RED}Failed: $FAILED_SUITES${NC}"
    echo "Duration: ${DURATION}s"
    echo
    
    if [[ $FAILED_SUITES -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed. Please check the output above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"