# Go Clean Architecture Template

A production-ready Go project template implementing Clean Architecture principles with SOLID design patterns, conventional commits, and semantic versioning.

## 📚 Documentation

- [Getting Started](getting-started.md) - Quick guide to create a new project from this template
- [Architecture Overview](architecture.md) - Detailed explanation of the Clean Architecture implementation
- [Project Structure](project-structure.md) - Directory layout and file organization
- [Development Guide](development.md) - Development workflow, tools, and best practices
- [Template Sync](template-sync.md) - Keep your project updated with template improvements
- [Examples](examples.md) - Complete feature implementation examples
- [API Documentation](api.md) - HTTP and gRPC API guidelines
- [Testing Guide](testing.md) - Testing strategies and examples
- [Deployment Guide](deployment.md) - Building and deploying your application

## 🎯 Template Features

- **Clean Architecture** - Clear separation of concerns with domain, use cases, adapters, and infrastructure layers
- **SOLID Principles** - Enforced throughout the codebase
- **Conventional Commits** - Automated commit message validation
- **Semantic Versioning** - Automatic version bumping based on commits
- **Pre-commit Hooks** - Code quality checks before commits
- **Docker Support** - Multi-stage builds and docker-compose
- **CI/CD Ready** - GitHub Actions workflows included
- **Testing Framework** - Unit and integration test structure
- **Code Generation** - Commands for scaffolding components
- **Hot Reload** - Development server with automatic reloading

## 🚀 Quick Start

```bash
# 1. Create a new repository from this template
git clone https://github.com/yourusername/gotemplaterepo.git myproject
cd myproject

# 2. Run the setup script
make setup-project PROJECT_NAME=myapp MODULE_PATH=github.com/yourusername/myapp

# 3. Install dependencies and tools
make install-tools
./scripts/install-hooks.sh

# 4. Start developing
make dev
```

For detailed instructions, see the [Getting Started Guide](getting-started.md).