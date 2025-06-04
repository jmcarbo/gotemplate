# Go Clean Architecture Template 🏗️

[![Template Tests](https://github.com/jmcarbo/gotemplate/actions/workflows/template-tests.yml/badge.svg)](https://github.com/jmcarbo/gotemplate/actions/workflows/template-tests.yml)
[![Go Version](https://img.shields.io/badge/Go-1.24-blue.svg)](https://golang.org/doc/go1.24)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A production-ready Go project template implementing Clean Architecture principles with SOLID design patterns, complete with testing, CI/CD, and project management tools.

## ✨ Features

- **🏛️ Clean Architecture** - Clear separation of concerns with domain, use cases, adapters, and infrastructure layers
- **💎 SOLID Principles** - Enforced throughout the codebase for maintainable and scalable applications
- **🔄 Template Synchronization** - Keep your projects updated with the latest template improvements
- **📦 Semantic Versioning** - Automated version management with conventional commits
- **🧪 Comprehensive Testing** - Unit, integration, and template functionality tests
- **🐳 Docker Support** - Multi-stage builds and docker-compose for local development
- **🔧 Development Tools** - Pre-configured linting, formatting, and git hooks
- **📚 Rich Documentation** - Architecture guides, examples, and best practices
- **🤖 GitHub Actions** - CI/CD pipelines for testing, building, and releasing

## 🚀 Quick Start

### Use this Template

1. Click the "Use this template" button on GitHub
2. Create your new repository
3. Clone and set up your project:

```bash
git clone https://github.com/yourusername/mynewproject.git
cd mynewproject
make setup-project PROJECT_NAME=mynewproject MODULE_PATH=github.com/yourusername/mynewproject
```

### Or Clone Directly

```bash
# Clone the template
git clone https://github.com/jmcarbo/gotemplate.git myproject
cd myproject

# Set up for your project
make setup-project PROJECT_NAME=myproject MODULE_PATH=github.com/yourusername/myproject

# Install tools and dependencies
make install-tools
./scripts/install-hooks.sh

# Start developing
make dev
```

## 📖 Documentation

- [Getting Started Guide](docs/getting-started.md) - Detailed setup instructions
- [Architecture Overview](docs/architecture.md) - Clean Architecture implementation
- [Project Structure](docs/project-structure.md) - Directory layout and conventions
- [Development Guide](docs/development.md) - Development workflow and best practices
- [Template Sync Guide](docs/template-sync.md) - Keep your project updated
- [Examples](docs/examples.md) - Complete feature implementation examples

## 🏗️ Project Structure

```
.
├── cmd/                    # Application entrypoints
├── internal/              # Private application code
│   ├── domain/           # Business logic and entities
│   ├── usecases/         # Application business rules
│   ├── adapters/         # Interface adapters (HTTP, gRPC, CLI)
│   └── infrastructure/   # External services (DB, cache, etc.)
├── pkg/                   # Public packages
├── docs/                  # Documentation
├── test/                  # Test suites
└── scripts/              # Utility scripts
```

## 🛠️ Available Commands

```bash
# Development
make run              # Run the application
make dev              # Run with hot reload
make build            # Build the binary
make test             # Run all tests
make lint             # Run linter
make fmt              # Format code

# Template Management
make template-check   # Check for template updates
make template-sync    # Sync with template updates

# Version Management
make version          # Show current version
make release          # Create a new release

# Docker
make docker-build     # Build Docker image
make docker-run       # Run in Docker
```

## 🧪 Testing

The template includes comprehensive tests:

```bash
# Run all template tests
make test-template

# Run specific test suites
make test-instantiation  # Test project creation
make test-sync          # Test template updates
make test-build-dev     # Test build commands
make test-version       # Test versioning
```

## 🔄 Keeping Your Project Updated

After creating your project, you can sync updates from the template:

```bash
# Check for updates
make template-check

# Preview changes
make template-sync-dry

# Apply updates
make template-sync
```

## 📋 Requirements

- Go 1.24 or higher
- Docker and Docker Compose
- Make
- Git

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. See our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This template is available under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Inspired by Clean Architecture principles by Robert C. Martin
- Built with best practices from the Go community
- Incorporates patterns from Domain-Driven Design

## 🔗 Resources

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

---

Made with ❤️ for the Go community