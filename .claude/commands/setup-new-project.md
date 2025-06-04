# Setup New Project

Adapt this template repository for a new project.

Initialize this template for a new project called {{PROJECT_NAME}} with module path {{MODULE_PATH}}:

1. Update go.mod with the new module path {{MODULE_PATH}}
2. Update all import statements throughout the codebase to use {{MODULE_PATH}}
3. Update README.md with {{PROJECT_NAME}} and project description
4. Update docker-compose.yml service names to use {{PROJECT_NAME}}
5. Update Dockerfile with appropriate labels
6. Update Makefile variables (APP_NAME, etc.)
7. Search and replace any references to "gotemplaterepo" with {{PROJECT_NAME}}
8. Update CLAUDE.md project name from "Selektor" to {{PROJECT_NAME}}
9. Clear out example entities, use cases, and tests (keep the structure)
10. Update .env.example with project-specific environment variables
11. Initialize git with fresh history: rm -rf .git && git init
12. Run make install-tools to ensure all tools are available
13. Run ./scripts/install-hooks.sh to set up pre-commit hooks
14. Verify everything works with: make lint && make test
15. Create initial commit with the message: "Initial commit from Go template"

Example values:
- PROJECT_NAME: myapp
- MODULE_PATH: github.com/myusername/myapp