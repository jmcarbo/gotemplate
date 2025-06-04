# Go Template Project Guidelines

This is a Go project following SOLID principles and Clean Architecture. The codebase is structured to maintain clear separation of concerns and dependency inversion.

## Architecture Overview

The project follows Clean Architecture with these layers:
- **Domain**: Core business logic, entities, value objects, and repository interfaces
- **Use Cases**: Application-specific business rules, commands, and queries
- **Adapters**: Interface adapters (HTTP, gRPC, CLI)
- **Infrastructure**: External dependencies (database, cache, messaging)

## Development Workflow

### Prerequisites
- Go 1.23 or higher
- Docker and Docker Compose
- Make

### Quick Start
```bash
# Install development tools
make install-tools

# Install pre-commit hooks
./scripts/install-hooks.sh

# Run the application
make run

# Run with hot reload
make dev
```

### Testing
```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests
make test-integration

# Generate coverage report
make test-coverage
```

### Code Quality
```bash
# Run linter
make lint

# Fix linting issues
make lint-fix

# Format code
make fmt

# Run security scan
make security

# Pre-commit checks
make pre-commit
```

## SOLID Principles

### Single Responsibility Principle
- Each module has one reason to change
- Domain entities contain only business logic
- Use cases orchestrate business operations
- Adapters handle protocol-specific concerns

### Open/Closed Principle
- Use interfaces for extensibility
- New features via new implementations, not modifications
- Strategy pattern for varying behaviors

### Liskov Substitution Principle
- All implementations must be substitutable for their interfaces
- No surprising behaviors in derived types
- Consistent error handling across implementations

### Interface Segregation Principle
- Small, focused interfaces
- Clients depend only on methods they use
- Domain-driven interface design

### Dependency Inversion Principle
- High-level modules don't depend on low-level modules
- Both depend on abstractions (interfaces)
- Repository pattern for data access
- Dependency injection for wiring

## Clean Code Guidelines

### Naming Conventions
- Interfaces: Repository suffix for data access (e.g., `UserRepository`)
- Use cases: Command/Query suffix (e.g., `CreateUserCommand`)
- Value objects: Descriptive names (e.g., `EmailAddress`, `UserID`)
- Errors: Error suffix (e.g., `NotFoundError`, `ValidationError`)

### Error Handling
- Use custom error types in domain layer
- Wrap errors with context
- Return errors, don't panic
- Use error variables for sentinel errors

### Testing
- Unit tests for domain logic
- Integration tests for infrastructure
- Mock interfaces, not implementations
- Table-driven tests for multiple scenarios
- Test file naming: `*_test.go`

### Package Structure
```
internal/
├── domain/           # Core business logic
│   ├── entities/     # Business entities
│   ├── valueobjects/ # Value objects
│   ├── repositories/ # Repository interfaces
│   └── services/     # Domain services
├── usecases/         # Application business rules
│   ├── commands/     # Write operations
│   └── queries/      # Read operations
├── adapters/         # Interface adapters
│   ├── http/         # HTTP handlers
│   ├── grpc/         # gRPC services
│   └── cli/          # CLI commands
└── infrastructure/   # External dependencies
    ├── database/     # Database implementations
    ├── cache/        # Cache implementations
    └── messaging/    # Message queue implementations
```

## Git Workflow

### Commit Messages (REQUIRED)
- **MUST use Conventional Commits format** - commits that don't follow this format will be rejected
- Format: `<type>(<scope>): <subject>`
- Types:
  - `feat`: New feature (MINOR version bump)
  - `fix`: Bug fix (PATCH version bump)
  - `docs`: Documentation only changes
  - `style`: Code style changes (formatting, missing semicolons, etc.)
  - `refactor`: Code refactoring without feature changes
  - `perf`: Performance improvements
  - `test`: Adding or correcting tests
  - `build`: Changes to build process or dependencies
  - `ci`: CI configuration changes
  - `chore`: Other changes that don't modify src or test files
  - `revert`: Reverts a previous commit
- Include scope when relevant (e.g., `feat(auth): add JWT support`)
- Breaking changes: Add `BREAKING CHANGE:` in commit body or `!` after type/scope
- Keep subject line under 50 characters
- Use imperative mood ("add" not "added" or "adds")

### Examples of Valid Commits
```
feat(user): add email verification
fix(auth): resolve token expiration issue
docs(readme): update installation instructions
refactor(database): optimize query performance
feat(api)!: change response format for endpoints
```

### Branch Strategy
- `main`: Production-ready code (protected, requires PR)
- `develop`: Integration branch
- Feature branches: `feature/description`
- Bugfix branches: `fix/description`
- Release branches: `release/v1.2.3`

## Versioning

### Semantic Versioning (SemVer)
This project follows [Semantic Versioning 2.0.0](https://semver.org/):
- Format: `MAJOR.MINOR.PATCH` (e.g., `v1.2.3`)
- **MAJOR**: Breaking API changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

### Version Management
```bash
# View current version
make version

# Create a new release (automatically determines version from commits)
make release

# Create specific version release
make release-patch  # v1.2.3 -> v1.2.4
make release-minor  # v1.2.3 -> v1.3.0
make release-major  # v1.2.3 -> v2.0.0
```

### Release Process
1. Commits on `develop` branch trigger automatic version calculation
2. Merge to `main` creates a release with:
   - Git tag with version
   - GitHub release with changelog
   - Docker image with version tag
   - Binary artifacts

### Changelog Generation
- Automatically generated from conventional commits
- Groups changes by type (Features, Bug Fixes, etc.)
- Includes breaking changes section
- Links to commits and issues

## CI/CD

### GitHub Actions
- Runs on push to main/develop and PRs
- Linting with golangci-lint
- Unit and integration tests
- Security scanning with Trivy
- Automatic releases on tags

### Pre-commit Hooks
- Code formatting (gofmt, goimports)
- Linting (golangci-lint)
- Import organization
- **Conventional commit message validation** (enforced)
- Secret detection (detect-secrets)
- Go mod tidy verification
- No large files check

## Performance Guidelines

### Optimization Rules
1. Measure before optimizing
2. Focus on algorithmic improvements
3. Use benchmarks to validate changes
4. Profile CPU and memory usage

### Best Practices
- Use context for cancellation
- Implement graceful shutdown
- Use connection pooling
- Cache expensive computations
- Prefer streaming over loading everything in memory

## Security

### General Rules
- Never commit secrets
- Use environment variables for configuration
- Validate all inputs
- Use prepared statements for SQL
- Implement rate limiting
- Use TLS for external communications

### Dependencies
- Keep dependencies minimal
- Regular security updates
- Use `go mod verify`
- Check for vulnerabilities with `make security`

## Documentation

### Code Documentation
- Document exported functions and types
- Explain "why", not "what"
- Include examples for complex APIs
- Keep documentation close to code

### API Documentation
- OpenAPI/Swagger for HTTP APIs
- Protocol buffer comments for gRPC
- Include request/response examples
- Document error responses

## Important Instructions

- Always run `make lint` before committing
- Always run `make test` before pushing
- Follow the established patterns in the codebase
- When in doubt, favor clarity over cleverness
- Write code for humans to read