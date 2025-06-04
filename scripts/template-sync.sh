#!/bin/bash
# Template Sync Script
# Synchronizes files from the template repository while preserving local customizations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SYNC_CONFIG=".template-sync.yml"
TEMPLATE_VERSION_FILE=".template-version"
TEMP_DIR=".template-sync-tmp"
BACKUP_DIR=".template-backup/$(date +%Y%m%d_%H%M%S)"

# Parse command line arguments
DRY_RUN=false
FORCE=false
VERBOSE=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be updated without making changes"
            echo "  --force      Skip confirmation prompts"
            echo "  --verbose    Show detailed output"
            echo "  --check      Check for available updates only"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Functions
log() {
    echo -e "${GREEN}[SYNC]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Check if yq is installed for YAML parsing
check_dependencies() {
    if ! command -v yq &> /dev/null; then
        error "yq is required for parsing YAML. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install yq
        else
            wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            chmod +x /usr/local/bin/yq
        fi
    fi
}

# Read configuration
read_config() {
    if [[ ! -f "$SYNC_CONFIG" ]]; then
        error "Configuration file $SYNC_CONFIG not found!"
        exit 1
    fi
    
    TEMPLATE_REPO=$(yq eval '.template.repository' "$SYNC_CONFIG")
    TEMPLATE_BRANCH=$(yq eval '.template.branch' "$SYNC_CONFIG")
    
    verbose "Template repository: $TEMPLATE_REPO"
    verbose "Template branch: $TEMPLATE_BRANCH"
}

# Get current template version
get_current_version() {
    if [[ -f "$TEMPLATE_VERSION_FILE" ]]; then
        cat "$TEMPLATE_VERSION_FILE"
    else
        echo "unknown"
    fi
}

# Get latest template version
get_latest_version() {
    git ls-remote --tags "$TEMPLATE_REPO" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1 || echo "main"
}

# Clone template repository
clone_template() {
    log "Cloning template repository..."
    rm -rf "$TEMP_DIR"
    git clone --quiet --depth 1 --branch "$TEMPLATE_BRANCH" "$TEMPLATE_REPO" "$TEMP_DIR"
}

# Check if file should be synced
should_sync_file() {
    local file="$1"
    local exclude_patterns=$(yq eval '.exclude[]' "$SYNC_CONFIG" 2>/dev/null)
    
    while IFS= read -r pattern; do
        if [[ "$file" == $pattern ]]; then
            verbose "Excluding $file (matches pattern: $pattern)"
            return 1
        fi
    done <<< "$exclude_patterns"
    
    return 0
}

# Get sync strategy for file
get_sync_strategy() {
    local file="$1"
    
    # Check overwrite files
    if yq eval '.overwrite[]' "$SYNC_CONFIG" | grep -q "^$file$"; then
        echo "overwrite"
        return
    fi
    
    # Check merge files
    if yq eval '.merge[]' "$SYNC_CONFIG" | grep -q "^$file$"; then
        echo "merge"
        return
    fi
    
    # Check create_if_missing patterns
    local create_patterns=$(yq eval '.create_if_missing[]' "$SYNC_CONFIG" 2>/dev/null)
    while IFS= read -r pattern; do
        if [[ "$file" == $pattern ]]; then
            echo "create_if_missing"
            return
        fi
    done <<< "$create_patterns"
    
    echo "skip"
}

# Backup file
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_path="$BACKUP_DIR/$file"
        mkdir -p "$(dirname "$backup_path")"
        cp "$file" "$backup_path"
        verbose "Backed up $file to $backup_path"
    fi
}

# Sync single file
sync_file() {
    local file="$1"
    local strategy="$2"
    local source="$TEMP_DIR/$file"
    local dest="$file"
    
    if [[ ! -f "$source" ]]; then
        verbose "Source file $source not found in template"
        return
    fi
    
    case "$strategy" in
        "overwrite")
            if [[ "$DRY_RUN" == "true" ]]; then
                log "[DRY RUN] Would overwrite $dest"
            else
                backup_file "$dest"
                mkdir -p "$(dirname "$dest")"
                cp "$source" "$dest"
                log "Updated $dest (overwrite)"
            fi
            ;;
        
        "merge")
            if [[ -f "$dest" ]]; then
                if ! diff -q "$source" "$dest" > /dev/null 2>&1; then
                    if [[ "$DRY_RUN" == "true" ]]; then
                        log "[DRY RUN] Would create merge file for $dest"
                    else
                        backup_file "$dest"
                        cp "$source" "${dest}.merge"
                        warn "Created ${dest}.merge - manual merge required"
                    fi
                fi
            else
                if [[ "$DRY_RUN" == "true" ]]; then
                    log "[DRY RUN] Would create $dest"
                else
                    mkdir -p "$(dirname "$dest")"
                    cp "$source" "$dest"
                    log "Created $dest"
                fi
            fi
            ;;
        
        "create_if_missing")
            if [[ ! -f "$dest" ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    log "[DRY RUN] Would create $dest"
                else
                    mkdir -p "$(dirname "$dest")"
                    cp "$source" "$dest"
                    log "Created $dest"
                fi
            else
                verbose "Skipping $dest (already exists)"
            fi
            ;;
        
        *)
            verbose "Skipping $file (strategy: $strategy)"
            ;;
    esac
}

# Process all files
sync_files() {
    log "Processing template files..."
    
    cd "$TEMP_DIR"
    find . -type f -name "*" | while read -r file; do
        # Remove leading ./
        file="${file#./}"
        
        # Skip git files
        if [[ "$file" =~ ^\.git/ ]]; then
            continue
        fi
        
        # Check if file should be synced
        if should_sync_file "$file"; then
            strategy=$(get_sync_strategy "$file")
            if [[ "$strategy" != "skip" ]]; then
                sync_file "$file" "$strategy"
            fi
        fi
    done
    cd - > /dev/null
}

# Run hooks
run_hooks() {
    local hook_type="$1"
    local hooks=$(yq eval ".hooks.${hook_type}[]" "$SYNC_CONFIG" 2>/dev/null)
    
    if [[ -n "$hooks" ]]; then
        log "Running ${hook_type} hooks..."
        while IFS= read -r hook; do
            if [[ "$DRY_RUN" == "true" ]]; then
                log "[DRY RUN] Would run: $hook"
            else
                verbose "Running: $hook"
                eval "$hook" || warn "Hook failed: $hook"
            fi
        done <<< "$hooks"
    fi
}

# Check for updates
check_updates() {
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    log "Current template version: $current_version"
    log "Latest template version: $latest_version"
    
    if [[ "$current_version" != "$latest_version" ]]; then
        log "Updates available!"
        return 0
    else
        log "Already up to date"
        return 1
    fi
}

# Main sync process
main() {
    log "Template Sync Tool"
    
    check_dependencies
    read_config
    
    if [[ "$CHECK_ONLY" == "true" ]]; then
        check_updates
        exit 0
    fi
    
    # Confirmation
    if [[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]]; then
        echo -e "${YELLOW}This will synchronize files from the template repository.${NC}"
        echo -e "${YELLOW}Local customizations in merge files will be preserved.${NC}"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Sync cancelled"
            exit 0
        fi
    fi
    
    # Create backup directory
    if [[ "$DRY_RUN" != "true" ]]; then
        mkdir -p "$BACKUP_DIR"
    fi
    
    # Run pre-sync hooks
    run_hooks "pre_sync"
    
    # Clone template
    clone_template
    
    # Sync files
    sync_files
    
    # Update version file
    if [[ "$DRY_RUN" != "true" ]]; then
        latest_version=$(cd "$TEMP_DIR" && git describe --tags --always)
        echo "$latest_version" > "$TEMPLATE_VERSION_FILE"
        log "Updated template version to $latest_version"
    fi
    
    # Run post-sync hooks
    run_hooks "post_sync"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    # Summary
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Dry run complete - no changes were made"
    else
        log "Sync complete!"
        if ls *.merge 2>/dev/null | grep -q .; then
            warn "Manual merge required for the following files:"
            ls *.merge
        fi
    fi
}

# Run main function
main