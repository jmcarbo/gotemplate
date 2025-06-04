.PHONY: all build test lint clean run docker-build docker-run help

BINARY_NAME=gotemplate
DOCKER_IMAGE=gotemplate:latest
GO_VERSION=1.23
GOBASE=$(shell pwd)
GOBIN=$(GOBASE)/bin
GOFILES=$(wildcard *.go)
GOLINT_VERSION=v1.61.0

GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

all: help

## Build:
build: ## Build the binary
	@echo '${GREEN}Building ${BINARY_NAME}...${RESET}'
	@go build -v -o $(GOBIN)/$(BINARY_NAME) ./cmd/api

build-linux: ## Build for Linux
	@echo '${GREEN}Building ${BINARY_NAME} for Linux...${RESET}'
	@GOOS=linux GOARCH=amd64 go build -v -o $(GOBIN)/$(BINARY_NAME)-linux-amd64 ./cmd/api

## Test:
test: ## Run tests
	@echo '${GREEN}Running tests...${RESET}'
	@go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...

test-unit: ## Run unit tests
	@echo '${GREEN}Running unit tests...${RESET}'
	@go test -v -race -short ./...

test-integration: ## Run integration tests
	@echo '${GREEN}Running integration tests...${RESET}'
	@go test -v -race -tags=integration ./test/integration/...

test-coverage: test ## Run tests with coverage report
	@echo '${GREEN}Generating coverage report...${RESET}'
	@go tool cover -html=coverage.txt -o coverage.html
	@echo '${CYAN}Coverage report generated: coverage.html${RESET}'

benchmark: ## Run benchmarks
	@echo '${GREEN}Running benchmarks...${RESET}'
	@go test -bench=. -benchmem ./...

## Lint:
lint: ## Run linter
	@echo '${GREEN}Running linter...${RESET}'
	@if ! command -v golangci-lint &> /dev/null; then \
		echo '${YELLOW}Installing golangci-lint...${RESET}'; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLINT_VERSION); \
	fi
	@golangci-lint run --config .golangci.yml

lint-fix: ## Run linter with fix
	@echo '${GREEN}Running linter with fixes...${RESET}'
	@golangci-lint run --fix --config .golangci.yml

## Dependencies:
deps: ## Download dependencies
	@echo '${GREEN}Downloading dependencies...${RESET}'
	@go mod download

tidy: ## Tidy dependencies
	@echo '${GREEN}Tidying dependencies...${RESET}'
	@go mod tidy

verify: ## Verify dependencies
	@echo '${GREEN}Verifying dependencies...${RESET}'
	@go mod verify

## Docker:
docker-build: ## Build Docker image
	@echo '${GREEN}Building Docker image...${RESET}'
	@docker build -t $(DOCKER_IMAGE) .

docker-run: ## Run Docker container
	@echo '${GREEN}Running Docker container...${RESET}'
	@docker run -it --rm -p 8080:8080 $(DOCKER_IMAGE)

docker-compose-up: ## Start services with docker-compose
	@echo '${GREEN}Starting services...${RESET}'
	@docker-compose up -d

docker-compose-down: ## Stop services with docker-compose
	@echo '${GREEN}Stopping services...${RESET}'
	@docker-compose down

## Development:
run: build ## Build and run the application
	@echo '${GREEN}Starting ${BINARY_NAME}...${RESET}'
	@$(GOBIN)/$(BINARY_NAME)

dev: ## Run with hot reload (requires air)
	@echo '${GREEN}Starting development server...${RESET}'
	@if ! command -v air &> /dev/null; then \
		echo '${YELLOW}Installing air...${RESET}'; \
		go install github.com/air-verse/air@latest; \
	fi
	@air

generate: ## Run go generate
	@echo '${GREEN}Running go generate...${RESET}'
	@go generate ./...

## Database:
migrate-up: ## Run database migrations up
	@echo '${GREEN}Running migrations up...${RESET}'
	@migrate -path ./internal/infrastructure/database/migrations -database "$${DATABASE_URL}" up

migrate-down: ## Run database migrations down
	@echo '${GREEN}Running migrations down...${RESET}'
	@migrate -path ./internal/infrastructure/database/migrations -database "$${DATABASE_URL}" down

migrate-create: ## Create a new migration (usage: make migrate-create name=migration_name)
	@echo '${GREEN}Creating migration...${RESET}'
	@migrate create -ext sql -dir ./internal/infrastructure/database/migrations -seq $(name)

## Quality:
fmt: ## Format code
	@echo '${GREEN}Formatting code...${RESET}'
	@go fmt ./...
	@if command -v gofumpt &> /dev/null; then \
		gofumpt -l -w .; \
	else \
		echo '${YELLOW}gofumpt not installed, skipping extra formatting${RESET}'; \
	fi

vet: ## Run go vet
	@echo '${GREEN}Running go vet...${RESET}'
	@go vet ./...

security: ## Run security check
	@echo '${GREEN}Running security check...${RESET}'
	@if ! command -v gosec &> /dev/null; then \
		echo '${YELLOW}Installing gosec...${RESET}'; \
		go install github.com/securego/gosec/v2/cmd/gosec@latest; \
	fi
	@gosec -quiet ./...

## Clean:
clean: ## Clean build artifacts
	@echo '${GREEN}Cleaning...${RESET}'
	@go clean
	@rm -rf $(GOBIN)
	@rm -f coverage.txt coverage.html

## CI/CD:
ci: deps lint test build ## Run CI pipeline

pre-commit: fmt vet lint test ## Run pre-commit checks

## Versioning:
version: ## Show current version
	@echo '${GREEN}Current version:${RESET}'
	@git describe --tags --always --abbrev=0 2>/dev/null || echo "v0.0.0"

version-next: ## Preview next version based on commits
	@echo '${GREEN}Next version will be:${RESET}'
	@if ! command -v svu &> /dev/null; then \
		echo '${YELLOW}Installing svu...${RESET}'; \
		go install github.com/caarlos0/svu@latest; \
	fi
	@svu next

release: ## Create a new release based on conventional commits
	@echo '${GREEN}Creating release...${RESET}'
	@if ! command -v svu &> /dev/null; then \
		echo '${YELLOW}Installing svu...${RESET}'; \
		go install github.com/caarlos0/svu@latest; \
	fi
	@VERSION=$$(svu next) && \
	git tag -a "$$VERSION" -m "Release $$VERSION" && \
	echo '${CYAN}Tagged version '$$VERSION'${RESET}'

release-patch: ## Force patch release
	@echo '${GREEN}Creating patch release...${RESET}'
	@if ! command -v svu &> /dev/null; then \
		echo '${YELLOW}Installing svu...${RESET}'; \
		go install github.com/caarlos0/svu@latest; \
	fi
	@VERSION=$$(svu patch) && \
	git tag -a "$$VERSION" -m "Release $$VERSION" && \
	echo '${CYAN}Tagged version '$$VERSION'${RESET}'

release-minor: ## Force minor release
	@echo '${GREEN}Creating minor release...${RESET}'
	@if ! command -v svu &> /dev/null; then \
		echo '${YELLOW}Installing svu...${RESET}'; \
		go install github.com/caarlos0/svu@latest; \
	fi
	@VERSION=$$(svu minor) && \
	git tag -a "$$VERSION" -m "Release $$VERSION" && \
	echo '${CYAN}Tagged version '$$VERSION'${RESET}'

release-major: ## Force major release
	@echo '${GREEN}Creating major release...${RESET}'
	@if ! command -v svu &> /dev/null; then \
		echo '${YELLOW}Installing svu...${RESET}'; \
		go install github.com/caarlos0/svu@latest; \
	fi
	@VERSION=$$(svu major) && \
	git tag -a "$$VERSION" -m "Release $$VERSION" && \
	echo '${CYAN}Tagged version '$$VERSION'${RESET}'

changelog: ## Generate changelog from commits
	@echo '${GREEN}Generating changelog...${RESET}'
	@if ! command -v git-cliff &> /dev/null; then \
		echo '${YELLOW}Installing git-cliff...${RESET}'; \
		cargo install git-cliff || echo '${YELLOW}Please install cargo/rust first${RESET}'; \
	fi
	@git-cliff --latest --unreleased

## Template Sync:
template-check: ## Check for template updates
	@echo '${GREEN}Checking for template updates...${RESET}'
	@./scripts/template-sync.sh --check

template-sync: ## Sync with template repository
	@echo '${GREEN}Syncing with template repository...${RESET}'
	@./scripts/template-sync.sh

template-sync-dry: ## Dry run template sync (show what would change)
	@echo '${GREEN}Running template sync in dry-run mode...${RESET}'
	@./scripts/template-sync.sh --dry-run --verbose

## Project Setup:
setup-project: ## Setup project from template (usage: make setup-project PROJECT_NAME=myapp MODULE_PATH=github.com/user/myapp)
	@if [ -z "$(PROJECT_NAME)" ] || [ -z "$(MODULE_PATH)" ]; then \
		echo '${YELLOW}Usage: make setup-project PROJECT_NAME=myapp MODULE_PATH=github.com/user/myapp${RESET}'; \
		exit 1; \
	fi
	@echo '${GREEN}Setting up project: $(PROJECT_NAME)${RESET}'
	@echo '${CYAN}Module path: $(MODULE_PATH)${RESET}'
	
	@echo '${GREEN}Updating go.mod...${RESET}'
	@go mod edit -module $(MODULE_PATH)
	
	@echo '${GREEN}Updating imports...${RESET}'
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		find . -type f -name "*.go" -exec sed -i '' 's|gotemplaterepo|$(MODULE_PATH)|g' {} +; \
	else \
		find . -type f -name "*.go" -exec sed -i 's|gotemplaterepo|$(MODULE_PATH)|g' {} +; \
	fi
	
	@echo '${GREEN}Updating Makefile...${RESET}'
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		sed -i '' 's/BINARY_NAME=gotemplate/BINARY_NAME=$(PROJECT_NAME)/g' Makefile; \
		sed -i '' 's/DOCKER_IMAGE=gotemplate/DOCKER_IMAGE=$(PROJECT_NAME)/g' Makefile; \
	else \
		sed -i 's/BINARY_NAME=gotemplate/BINARY_NAME=$(PROJECT_NAME)/g' Makefile; \
		sed -i 's/DOCKER_IMAGE=gotemplate/DOCKER_IMAGE=$(PROJECT_NAME)/g' Makefile; \
	fi
	
	@echo '${GREEN}Updating docker-compose.yml...${RESET}'
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		sed -i '' 's/gotemplate/$(PROJECT_NAME)/g' docker-compose.yml; \
	else \
		sed -i 's/gotemplate/$(PROJECT_NAME)/g' docker-compose.yml; \
	fi
	
	@echo '${GREEN}Updating CLAUDE.md...${RESET}'
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		sed -i '' 's/Go Template/$(PROJECT_NAME)/g' CLAUDE.md; \
	else \
		sed -i 's/Go Template/$(PROJECT_NAME)/g' CLAUDE.md; \
	fi
	
	@echo '${GREEN}Cleaning example files...${RESET}'
	@rm -rf internal/domain/entities/user.go internal/domain/entities/user_test.go || true
	@rm -rf internal/usecases/commands/create_user.go || true
	@rm -rf internal/domain/repositories/user_repository.go || true
	
	@echo '${GREEN}Running go mod tidy...${RESET}'
	@go mod tidy
	
	@echo '${GREEN}Setting up template sync...${RESET}'
	@echo "https://github.com/jmcarbo/gotemplate" > .template-repo
	@git describe --tags --always 2>/dev/null > .template-version || echo "v0.0.0" > .template-version
	
	@echo '${GREEN}Creating initial project files...${RESET}'
	@echo "# $(PROJECT_NAME)" > README.md
	@echo "" >> README.md
	@echo "Project created from Go Clean Architecture template." >> README.md
	@echo "" >> README.md
	@echo "## Getting Started" >> README.md
	@echo "" >> README.md
	@echo "See [docs/README.md](docs/README.md) for documentation." >> README.md
	
	@echo '${CYAN}Project setup complete!${RESET}'
	@echo '${CYAN}Next steps:${RESET}'
	@echo '  1. Update README.md with your project information'
	@echo '  2. Create .env file: cp .env.example .env'
	@echo '  3. Install tools: make install-tools'
	@echo '  4. Install hooks: ./scripts/install-hooks.sh'
	@echo '  5. Run tests: make test'
	@echo '  6. To sync with template updates: ./scripts/template-sync.sh'

## Tools:
install-tools: ## Install development tools
	@echo '${GREEN}Installing development tools...${RESET}'
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLINT_VERSION)
	@go install github.com/air-verse/air@latest
	@go install mvdan.cc/gofumpt@latest
	@go install github.com/securego/gosec/v2/cmd/gosec@latest
	@go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	@go install github.com/swaggo/swag/cmd/swag@latest
	@go install github.com/vektra/mockery/v2@latest
	@go install github.com/caarlos0/svu@latest
	@pip install --user commitizen || echo '${YELLOW}Please install Python/pip for commitizen${RESET}'
	@echo '${CYAN}Tools installed successfully${RESET}'

## Template Tests:
test-template: ## Run local template test
	@echo '${GREEN}Running template test...${RESET}'
	@./test/test_template.sh

## Help:
help: ## Show this help
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)