# Getting Started

This guide will walk you through creating a new Go project from this template repository.

## Prerequisites

Before starting, ensure you have the following installed:

- Go 1.24 or higher
- Docker and Docker Compose
- Make
- Git
- Python 3.x (for commitizen)

## Creating a New Project

### Step 1: Clone the Template

```bash
# Clone the template repository
git clone https://github.com/yourusername/gotemplaterepo.git myproject
cd myproject

# Remove the template's git history
rm -rf .git
git init
```

### Step 2: Customize for Your Project

You can either use the automated setup or manually configure your project.

#### Option A: Automated Setup (Recommended)

```bash
# Run the setup script with your project details
make setup-project PROJECT_NAME=myapp MODULE_PATH=github.com/yourusername/myapp
```

This command will:
- Update go.mod with your module path
- Replace all imports throughout the codebase
- Update configuration files
- Clean up example code
- Update documentation

#### Option B: Manual Setup

If you prefer manual setup or the automated script encounters issues:

1. **Update go.mod**
   ```bash
   go mod edit -module github.com/yourusername/myapp
   ```

2. **Update imports** - Replace all occurrences of the template module path:
   ```bash
   find . -type f -name "*.go" -exec sed -i '' 's|gotemplaterepo|github.com/yourusername/myapp|g' {} +
   ```

3. **Update configuration files**:
   - `Makefile`: Change `BINARY_NAME` and `DOCKER_IMAGE`
   - `docker-compose.yml`: Update service names
   - `CLAUDE.md`: Update project name
   - `README.md`: Update with your project information

4. **Clean up examples**:
   ```bash
   # Remove example entities and tests
   rm -f internal/domain/entities/user*.go
   rm -f internal/usecases/commands/create_user*.go
   ```

### Step 3: Install Dependencies

```bash
# Install Go dependencies
go mod tidy

# Install development tools
make install-tools

# Install pre-commit hooks
./scripts/install-hooks.sh
```

### Step 4: Configure Your Environment

1. **Create .env file**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Set up your database** (if needed):
   ```bash
   # Start PostgreSQL with docker-compose
   docker-compose up -d postgres
   
   # Run migrations
   make migrate-up
   ```

### Step 5: Verify Setup

```bash
# Run linting
make lint

# Run tests
make test

# Build the application
make build

# Run the application
make run
```

### Step 6: Initial Commit

```bash
# Add all files
git add .

# Create initial commit (will be validated by commitizen)
git commit -m "feat: initial project setup from Go template"

# Set up your remote repository
git remote add origin https://github.com/yourusername/myapp.git
git push -u origin main
```

## Next Steps

### 1. Define Your Domain

Start by creating your domain entities:

```bash
# Use the Claude Code command to create an entity
# In Claude Code: /create-entity Product
```

### 2. Create Use Cases

Add your business logic:

```bash
# Use the Claude Code command to create use cases
# In Claude Code: /create-usecase command CreateProduct
```

### 3. Add API Endpoints

Expose your use cases through HTTP or gRPC:

```bash
# Use the Claude Code command to add endpoints
# In Claude Code: /add-http-endpoint CreateProduct
```

### 4. Implement Persistence

Create repository implementations:

```bash
# Use the Claude Code command to implement repositories
# In Claude Code: /implement-repository ProductRepository
```

## Development Workflow

### Running the Application

```bash
# Development mode with hot reload
make dev

# Production build and run
make build && make run

# Using Docker
make docker-build && make docker-run
```

### Testing

```bash
# Run all tests
make test

# Run with coverage
make test-coverage

# Run only unit tests
make test-unit

# Run integration tests
make test-integration
```

### Code Quality

```bash
# Format code
make fmt

# Run linter
make lint

# Security scan
make security

# All pre-commit checks
make pre-commit
```

### Version Management

```bash
# Check current version
make version

# Preview next version
make version-next

# Create a release
make release
```

## Troubleshooting

### Import Errors After Setup

If you encounter import errors after setting up your project:

1. Ensure go.mod has the correct module path
2. Run `go mod tidy` to update dependencies
3. Check that all imports were updated correctly

### Pre-commit Hook Failures

If commits are rejected:

1. Ensure your commit message follows conventional commit format
2. Run `make pre-commit` to check for issues
3. Fix any linting or test failures

### Tool Installation Issues

If `make install-tools` fails:

1. Ensure you have proper Go environment setup
2. Check your GOPATH and GOBIN
3. Install tools individually if needed

## Keeping Your Project Updated

After creating your project, you can sync updates from the template:

```bash
# Check for updates
make template-check

# Preview changes
make template-sync-dry

# Apply updates
make template-sync
```

See [Template Sync Guide](template-sync.md) for detailed information.

## Additional Resources

- [Architecture Overview](architecture.md) - Understanding the project structure
- [Development Guide](development.md) - Detailed development practices
- [Template Sync Guide](template-sync.md) - Keeping your project updated
- [Claude Code Commands](.claude/commands) - Available code generation commands