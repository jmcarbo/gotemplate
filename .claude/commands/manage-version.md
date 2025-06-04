# Manage Version

Handle semantic versioning and releases for the project.

Manage version for {{ACTION}}:

1. If ACTION is "bump":
   - Analyze recent commits since last tag using conventional commits
   - Determine version bump type (major/minor/patch)
   - Update VERSION file if it exists
   - Create annotated git tag with format v{{VERSION}}
   - Generate changelog from commits
   - Ensure all tests pass before tagging

2. If ACTION is "release":
   - Create GitHub release with changelog
   - Build release artifacts
   - Tag Docker images with version
   - Update version references in documentation

3. If ACTION is "check":
   - Show current version
   - List commits since last release
   - Preview next version based on commits
   - Show which commits would trigger which version bump

Remember:
- feat: triggers MINOR bump
- fix: triggers PATCH bump
- BREAKING CHANGE or feat!: triggers MAJOR bump
- Other types don't affect version

Example conventional commits:
- feat(api): add user authentication
- fix(db): resolve connection leak
- feat!: redesign API response format
- chore: update dependencies (no version change)