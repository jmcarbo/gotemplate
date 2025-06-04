# Project Structure

This document explains the directory layout and file organization conventions used in this template.

## Directory Tree

```
.
├── .claude/                    # Claude Code configuration
│   └── commands/              # Custom command templates
├── .github/                   # GitHub configuration
│   └── workflows/            # CI/CD workflows
├── build/                     # Build artifacts (gitignored)
├── cmd/                       # Application entry points
│   └── api/                  # Main API server
│       └── main.go          # Application entry point
├── configs/                   # Configuration files
├── deployments/              # Deployment configurations
│   ├── docker/              # Docker-specific files
│   └── k8s/                 # Kubernetes manifests
├── docs/                     # Documentation
├── internal/                 # Private application code
│   ├── domain/              # Core business logic (innermost layer)
│   │   ├── entities/        # Business entities
│   │   ├── valueobjects/    # Value objects
│   │   ├── repositories/    # Repository interfaces
│   │   ├── services/        # Domain services
│   │   └── errors/          # Domain-specific errors
│   ├── usecases/            # Application business rules
│   │   ├── commands/        # Write operations
│   │   ├── queries/         # Read operations
│   │   └── dto/             # Data transfer objects
│   ├── adapters/            # Interface adapters
│   │   ├── http/            # HTTP/REST handlers
│   │   ├── grpc/            # gRPC service implementations
│   │   └── cli/             # CLI command implementations
│   └── infrastructure/      # External services (outermost layer)
│       ├── database/        # Database implementations
│       ├── cache/           # Cache implementations
│       └── messaging/       # Message queue implementations
├── pkg/                      # Public packages (can be imported by external projects)
│   ├── errors/              # Error handling utilities
│   └── logger/              # Logging utilities
├── scripts/                  # Utility scripts
├── test/                     # Additional test files
│   ├── integration/         # Integration tests
│   ├── e2e/                 # End-to-end tests
│   └── fixtures/            # Test data and fixtures
├── .czrc                    # Commitizen configuration
├── .dockerignore            # Docker ignore patterns
├── .editorconfig            # Editor configuration
├── .env.example             # Example environment variables
├── .gitignore               # Git ignore patterns
├── .golangci.yml            # Linter configuration
├── .pre-commit-config.yaml  # Pre-commit hooks
├── CLAUDE.md                # Project guidelines for Claude Code
├── cliff.toml               # Git-cliff changelog configuration
├── docker-compose.yml       # Docker Compose configuration
├── Dockerfile               # Multi-stage Docker build
├── go.mod                   # Go module definition
├── go.sum                   # Go module checksums
├── Makefile                 # Build and development tasks
├── README.md                # Project overview
└── VERSION                  # Current version file
```

## Directory Explanations

### `/cmd`
Contains application entry points. Each subdirectory is a main package:
- `api/` - HTTP/gRPC server entry point
- Future: `cli/`, `worker/`, `migration/` etc.

### `/internal`
Private application code that cannot be imported by other projects.

#### `/internal/domain`
The core of the application, containing business logic:
- **entities/** - Business objects with identity
- **valueobjects/** - Immutable objects without identity
- **repositories/** - Interfaces for data persistence
- **services/** - Domain logic spanning multiple entities
- **errors/** - Business rule violations and domain errors

#### `/internal/usecases`
Application-specific business rules:
- **commands/** - Operations that modify state
- **queries/** - Operations that read state
- **dto/** - Data structures for use case input/output

#### `/internal/adapters`
Converts between external formats and use cases:
- **http/** - REST API handlers and middleware
- **grpc/** - gRPC service implementations
- **cli/** - Command-line interface adapters

#### `/internal/infrastructure`
Implementations of external services:
- **database/** - Repository implementations
- **cache/** - Caching layer implementations
- **messaging/** - Message queue implementations

### `/pkg`
Public packages that can be imported by external projects:
- Utility functions
- Common types
- Shared constants

### `/test`
Additional test files not co-located with source:
- **integration/** - Tests requiring external services
- **e2e/** - Full system tests
- **fixtures/** - Test data and mocks

### `/scripts`
Utility scripts for development:
- `install-hooks.sh` - Sets up git hooks
- Database migrations
- Code generation scripts

### `/deployments`
Deployment configurations:
- **docker/** - Docker-specific files
- **k8s/** - Kubernetes manifests
- **terraform/** - Infrastructure as code

## File Naming Conventions

### Go Files
- Use lowercase with underscores: `user_repository.go`
- Test files: `user_repository_test.go`
- Interfaces in separate files: `interfaces.go`

### Configuration Files
- Environment-specific: `.env.development`, `.env.production`
- YAML for structured config: `config.yml`

## Package Design Guidelines

### Domain Package Rules
1. No external dependencies
2. Pure Go stdlib only
3. Define interfaces, not implementations
4. Export only what's necessary

### Use Case Package Rules
1. Depend only on domain
2. One file per use case
3. Clear input/output structures
4. Handle orchestration logic

### Infrastructure Package Rules
1. Implement domain interfaces
2. Handle external service details
3. Can use any external library
4. Contain retry/circuit breaker logic

## Import Organization

Imports should be organized in groups:
1. Standard library
2. External packages
3. Internal packages

Example:
```go
import (
    // Standard library
    "context"
    "fmt"
    "time"
    
    // External packages
    "github.com/gorilla/mux"
    "github.com/sirupsen/logrus"
    
    // Internal packages
    "github.com/yourusername/myapp/internal/domain/entities"
    "github.com/yourusername/myapp/internal/usecases/commands"
)
```

## Test Organization

### Unit Tests
- Co-located with source files
- Test single units in isolation
- Mock external dependencies
- Fast execution

### Integration Tests
- In `/test/integration`
- Test multiple components together
- Use real external services (in containers)
- Slower execution

### Naming Convention
- Test functions: `Test<FunctionName>_<Scenario>`
- Benchmarks: `Benchmark<FunctionName>`
- Examples: `Example<FunctionName>`

## Configuration Management

### Environment Variables
- All configuration through environment
- `.env.example` documents all variables
- Never commit `.env` files

### Configuration Loading Priority
1. Environment variables
2. Configuration files
3. Default values

## Code Generation

### When to Generate Code
- Mocks for testing
- API clients from OpenAPI
- SQL boilerplate
- Protocol buffer code

### Generated File Convention
- Suffix with `_gen.go`
- Header comment: `// Code generated by <tool>; DO NOT EDIT.`
- Exclude from linting

## Module Boundaries

### Clear Separation
- Domain has no outer dependencies
- Use cases depend only on domain
- Adapters depend on use cases
- Infrastructure can depend on anything

### Dependency Injection
- Interfaces defined in inner layers
- Implementations in outer layers
- Wiring happens in main.go

## Best Practices

1. **Keep domain pure** - No frameworks, no external libs
2. **Thin adapters** - Only conversion logic
3. **Fat domain** - Rich business logic in entities
4. **Clear boundaries** - No cross-layer imports
5. **Testability first** - Design for testing
6. **Single purpose** - Each package has one clear purpose