# Template Synchronization

This guide explains how to keep your project synchronized with updates from the template repository.

## Overview

When you create a project from this template, you get a snapshot of the template at that point in time. The template sync feature allows you to:

- Pull updates from the template repository
- Preserve your local customizations
- Handle conflicts intelligently
- Track which template version you're using

## How It Works

The sync system uses a configuration file (`.template-sync.yml`) to determine:
- Which files should be synchronized
- How to handle conflicts
- Which files to never touch

### File Categories

1. **Overwrite Files**: Always replaced with template version
   - Configuration files (`.editorconfig`, `.gitignore`, etc.)
   - CI/CD workflows
   - Build scripts

2. **Merge Files**: Create `.merge` files for manual review
   - `Makefile`
   - `docker-compose.yml`
   - `Dockerfile`

3. **Create If Missing**: Only added if they don't exist
   - Documentation files
   - Command templates

4. **Excluded Files**: Never synchronized
   - Application code (`internal/`, `cmd/`, `pkg/`)
   - `README.md`
   - `go.mod`, `go.sum`
   - Environment files

## Usage

### Manual Sync

#### Check for Updates
```bash
make template-check
# or
./scripts/template-sync.sh --check
```

#### Dry Run (Preview Changes)
```bash
make template-sync-dry
# or
./scripts/template-sync.sh --dry-run --verbose
```

#### Perform Sync
```bash
make template-sync
# or
./scripts/template-sync.sh
```

### Automated Sync via GitHub Actions

The template includes a GitHub Action that:
- Runs weekly to check for updates
- Can be triggered manually
- Creates a pull request with changes

To enable automated sync:

1. Go to Actions tab in your repository
2. Enable the "Template Sync" workflow
3. Optionally configure the schedule in `.github/workflows/template-sync.yml`

### Command Line Options

```bash
./scripts/template-sync.sh [OPTIONS]

Options:
  --dry-run    Show what would be updated without making changes
  --force      Skip confirmation prompts
  --verbose    Show detailed output
  --check      Check for available updates only
  --help       Show help message
```

## Configuration

The `.template-sync.yml` file controls the sync behavior:

```yaml
template:
  repository: https://github.com/yourusername/gotemplaterepo
  branch: main

# Files to always overwrite
overwrite:
  - .editorconfig
  - .gitignore
  - .golangci.yml

# Files to merge manually
merge:
  - Makefile
  - docker-compose.yml

# Files to create only if missing
create_if_missing:
  - docs/*.md
  - .claude/commands/*.md

# Files to never sync
exclude:
  - README.md
  - internal/**
  - cmd/**
```

## Handling Conflicts

### Merge Files

When a file is marked for merge and has local changes:
1. The template version is saved as `filename.merge`
2. Review the differences
3. Manually merge changes
4. Delete the `.merge` file

Example:
```bash
# After sync, you might see:
$ ls *.merge
Makefile.merge

# Review differences
$ diff Makefile Makefile.merge

# Manually merge changes
$ vim Makefile

# Remove merge file
$ rm Makefile.merge
```

### Resolving Issues

If sync fails:

1. **Check git status**: Ensure you have no uncommitted changes
2. **Review errors**: The script provides detailed error messages
3. **Manual sync**: You can manually copy files from the template

## Best Practices

### 1. Regular Updates
- Run `make template-check` periodically
- Subscribe to template repository releases
- Review changelogs before syncing

### 2. Before Syncing
- Commit all local changes
- Run tests to ensure everything works
- Review the dry-run output

### 3. After Syncing
- Review all changes carefully
- Manually merge any `.merge` files
- Run tests again
- Update your own documentation if needed

### 4. Customization
- Modify `.template-sync.yml` to suit your needs
- Add project-specific files to the exclude list
- Document any permanent divergences

## Tracking Template Version

Your project tracks the template version in `.template-version`. This helps:
- Identify which template version you're based on
- Determine available updates
- Track sync history

```bash
# View current template version
cat .template-version

# View template sync history
git log --oneline -- .template-version
```

## Advanced Usage

### Custom Sync Configuration

Create a custom sync configuration for your project:

```yaml
# .template-sync.yml
template:
  repository: https://github.com/yourusername/gotemplaterepo
  branch: main

# Add project-specific exclusions
exclude:
  - README.md
  - internal/**
  - cmd/**
  - my-custom-file.go
  - configs/production.yml

# Add custom hooks
hooks:
  pre_sync:
    - "make test"
  post_sync:
    - "go mod tidy"
    - "make install-tools"
```

### Fork-Based Workflow

If you've forked the template:

1. Update `.template-sync.yml` to point to the original template
2. Sync updates from upstream
3. Apply your fork-specific changes

### Partial Sync

To sync only specific files:

1. Temporarily modify `.template-sync.yml`
2. Run sync
3. Restore original configuration

## Troubleshooting

### Common Issues

#### "yq: command not found"
Install yq:
```bash
# macOS
brew install yq

# Linux
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

#### "Permission denied"
Make the script executable:
```bash
chmod +x scripts/template-sync.sh
```

#### Merge Conflicts
1. The sync created `.merge` files
2. Manually review and merge changes
3. Delete `.merge` files when done

#### Sync Breaks Something
1. Check the backup directory: `.template-backup/`
2. Restore files if needed
3. Add problematic files to exclude list

## FAQ

### Q: Will sync overwrite my application code?
A: No, application directories (`internal/`, `cmd/`, `pkg/`) are excluded by default.

### Q: Can I sync from a private template repository?
A: Yes, ensure your git credentials have access to the template repository.

### Q: How do I stop syncing a specific file?
A: Add it to the `exclude` section in `.template-sync.yml`.

### Q: Can I sync from a specific tag or commit?
A: Yes, modify the `branch` field in `.template-sync.yml` to use a tag or commit SHA.

### Q: What if I've heavily customized a synced file?
A: Move it to the `exclude` list to preserve your customizations.

## Contributing Back

If you've made improvements that could benefit the template:

1. Fork the template repository
2. Apply your improvements
3. Submit a pull request
4. Help other projects benefit from your enhancements