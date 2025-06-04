# Sync Template

Synchronize your project with updates from the template repository.

Perform template sync operation {{ACTION}}:

1. If ACTION is "check":
   - Check if template updates are available
   - Compare current version with latest template version
   - List files that would be updated

2. If ACTION is "preview":
   - Run sync in dry-run mode
   - Show all files that would be changed
   - Display merge conflicts that would occur
   - No actual changes are made

3. If ACTION is "sync":
   - Backup current files
   - Pull latest changes from template
   - Apply updates according to .template-sync.yml
   - Create .merge files for conflicts
   - Update .template-version

4. If ACTION is "configure":
   - Review and modify .template-sync.yml
   - Add/remove files from sync categories
   - Update exclude patterns
   - Configure hooks

Important:
- Always commit changes before syncing
- Review .merge files and manually resolve conflicts
- Run tests after syncing to ensure nothing breaks
- Some files like README.md and application code are never synced

Commands:
- make template-check
- make template-sync-dry
- make template-sync