# Architecture Overview

This template implements Clean Architecture (also known as Hexagonal Architecture or Ports and Adapters) with a strong emphasis on SOLID principles and Domain-Driven Design (DDD).

## Clean Architecture Principles

The architecture follows these core principles:

1. **Independence of Frameworks** - The business logic doesn't depend on any external framework
2. **Testability** - Business rules can be tested without UI, database, or external services
3. **Independence of UI** - The UI can change without changing the business logic
4. **Independence of Database** - Business rules don't know about the database
5. **Independence of External Services** - Business rules don't depend on external APIs

## Layer Structure

```
┌─────────────────────────────────────────────────────────────┐
│                        External World                        │
│  (HTTP Requests, gRPC Calls, CLI Commands, Cron Jobs, etc.) │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                    Adapters Layer                            │
│         (HTTP Handlers, gRPC Services, CLI Commands)         │
│                  ┌─────────────────┐                         │
│                  │   Presenters    │                         │
│                  │   Controllers   │                         │
│                  └────────┬────────┘                         │
└──────────────────────────┼──────────────────────────────────┘
                          │
┌──────────────────────────┼──────────────────────────────────┐
│                  Use Cases Layer                             │
│              (Application Business Rules)                     │
│          ┌─────────────────────────────┐                     │
│          │   Commands    │   Queries   │                     │
│          │  (Write Ops)  │ (Read Ops)  │                     │
│          └───────┬───────┴─────────────┘                     │
└─────────────────┼───────────────────────────────────────────┘
                  │
┌─────────────────┼───────────────────────────────────────────┐
│            Domain Layer (Enterprise Business Rules)           │
│    ┌────────────┴──────────┬─────────────┬────────────┐     │
│    │      Entities         │    Value    │   Domain   │     │
│    │ (Business Objects)    │   Objects   │  Services  │     │
│    └───────────────────────┴─────────────┴────────────┘     │
│    ┌─────────────────────────────────────────────────┐      │
│    │           Repository Interfaces                  │      │
│    │         (Ports for Data Access)                 │      │
│    └─────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
                          │
┌──────────────────────────┼──────────────────────────────────┐
│                Infrastructure Layer                           │
│         (Frameworks, Drivers, External Services)              │
│  ┌─────────────┬──────────────┬────────────────────────┐    │
│  │  Database   │    Cache     │   Message Queue        │    │
│  │   (MySQL,   │   (Redis,    │  (RabbitMQ, Kafka)    │    │
│  │  PostgreSQL)│  Memcached)  │                        │    │
│  └─────────────┴──────────────┴────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Domain Layer (Core Business Logic)

**Location**: `internal/domain/`

**Components**:
- **Entities**: Core business objects with identity
- **Value Objects**: Immutable objects without identity
- **Repository Interfaces**: Contracts for data persistence
- **Domain Services**: Business logic spanning multiple entities
- **Domain Events**: Business events (if using event-driven architecture)

**Rules**:
- No dependencies on outer layers
- Pure Go code, no framework dependencies
- Contains all business rules and validations

**Example Entity**:
```go
// internal/domain/entities/product.go
type Product struct {
    ID          ProductID
    Name        string
    Price       Money
    Stock       int
    CategoryID  CategoryID
    CreatedAt   time.Time
    UpdatedAt   time.Time
}

func NewProduct(name string, price Money, stock int, categoryID CategoryID) (*Product, error) {
    if name == "" {
        return nil, ErrInvalidProductName
    }
    if stock < 0 {
        return nil, ErrInvalidStock
    }
    // Business rules validation
    return &Product{
        ID:         NewProductID(),
        Name:       name,
        Price:      price,
        Stock:      stock,
        CategoryID: categoryID,
        CreatedAt:  time.Now(),
        UpdatedAt:  time.Now(),
    }, nil
}
```

### 2. Use Cases Layer (Application Business Rules)

**Location**: `internal/usecases/`

**Components**:
- **Commands**: Write operations that change state
- **Queries**: Read operations that don't change state
- **DTOs**: Data Transfer Objects for input/output

**Rules**:
- Orchestrates the flow of data to and from entities
- Implements application-specific business rules
- Depends only on domain layer

**Example Use Case**:
```go
// internal/usecases/commands/create_product.go
type CreateProductCommand struct {
    repo    repositories.ProductRepository
    events  EventPublisher
}

func (c *CreateProductCommand) Execute(ctx context.Context, input CreateProductInput) (*CreateProductOutput, error) {
    // Application logic
    product, err := entities.NewProduct(
        input.Name,
        entities.NewMoney(input.Price, input.Currency),
        input.Stock,
        entities.CategoryID(input.CategoryID),
    )
    if err != nil {
        return nil, err
    }
    
    // Persist through repository
    if err := c.repo.Save(ctx, product); err != nil {
        return nil, err
    }
    
    // Publish domain event
    c.events.Publish(ProductCreatedEvent{ProductID: product.ID})
    
    return &CreateProductOutput{
        ID:        product.ID.String(),
        CreatedAt: product.CreatedAt,
    }, nil
}
```

### 3. Adapters Layer (Interface Adapters)

**Location**: `internal/adapters/`

**Components**:
- **HTTP Handlers**: REST API endpoints
- **gRPC Services**: RPC service implementations
- **CLI Commands**: Command-line interface
- **Presenters**: Format data for responses

**Rules**:
- Converts data between use cases and external format
- Implements framework-specific code
- Depends on use cases layer

**Example HTTP Handler**:
```go
// internal/adapters/http/product_handler.go
type ProductHandler struct {
    createProduct *commands.CreateProductCommand
}

func (h *ProductHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
    var req CreateProductRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondWithError(w, http.StatusBadRequest, err)
        return
    }
    
    // Convert HTTP request to use case input
    input := commands.CreateProductInput{
        Name:       req.Name,
        Price:      req.Price,
        Currency:   req.Currency,
        Stock:      req.Stock,
        CategoryID: req.CategoryID,
    }
    
    output, err := h.createProduct.Execute(r.Context(), input)
    if err != nil {
        respondWithError(w, http.StatusInternalServerError, err)
        return
    }
    
    // Convert use case output to HTTP response
    respondWithJSON(w, http.StatusCreated, CreateProductResponse{
        ID:        output.ID,
        CreatedAt: output.CreatedAt,
    })
}
```

### 4. Infrastructure Layer (Frameworks & Drivers)

**Location**: `internal/infrastructure/`

**Components**:
- **Database**: Repository implementations
- **Cache**: Caching implementations
- **Messaging**: Message queue implementations
- **External Services**: Third-party API clients

**Rules**:
- Implements interfaces defined in domain layer
- Contains all the messy details
- Can depend on any layer

**Example Repository Implementation**:
```go
// internal/infrastructure/database/postgres_product_repository.go
type PostgresProductRepository struct {
    db *sql.DB
}

func (r *PostgresProductRepository) Save(ctx context.Context, product *entities.Product) error {
    query := `
        INSERT INTO products (id, name, price, currency, stock, category_id, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `
    _, err := r.db.ExecContext(ctx, query,
        product.ID,
        product.Name,
        product.Price.Amount,
        product.Price.Currency,
        product.Stock,
        product.CategoryID,
        product.CreatedAt,
        product.UpdatedAt,
    )
    return err
}

func (r *PostgresProductRepository) FindByID(ctx context.Context, id entities.ProductID) (*entities.Product, error) {
    // Implementation details
}
```

## Dependency Flow

The dependency flow follows the Dependency Inversion Principle:

```
Adapters → Use Cases → Domain ← Infrastructure
```

- Inner layers define interfaces
- Outer layers implement interfaces
- Dependencies point inward
- No circular dependencies

## SOLID Principles in Action

### Single Responsibility Principle (SRP)
- Each layer has a single reason to change
- Entities change only for business rule changes
- Use cases change only for application logic changes

### Open/Closed Principle (OCP)
- New features are added by creating new use cases
- Existing code is extended through interfaces

### Liskov Substitution Principle (LSP)
- Repository implementations are interchangeable
- Any cache implementation can be used

### Interface Segregation Principle (ISP)
- Small, focused interfaces (e.g., Reader, Writer)
- Clients depend only on methods they use

### Dependency Inversion Principle (DIP)
- High-level modules (domain) don't depend on low-level modules
- Both depend on abstractions (interfaces)

## Benefits

1. **Testability** - Each layer can be tested independently
2. **Maintainability** - Changes are isolated to specific layers
3. **Flexibility** - Easy to swap implementations
4. **Clarity** - Clear separation of concerns
5. **Scalability** - Easy to add new features without affecting existing code

## Common Patterns

### Repository Pattern
Abstracts data access behind interfaces defined in the domain layer.

### Command/Query Separation (CQS)
Separates read operations (queries) from write operations (commands).

### Dependency Injection
Dependencies are injected rather than created, enabling loose coupling.

### Factory Pattern
Used for creating complex domain objects with validation.

### Value Objects
Immutable objects that represent concepts in the domain.

## Anti-patterns to Avoid

1. **Anemic Domain Model** - Entities with only getters/setters and no behavior
2. **Service Layer Bloat** - Putting all logic in services instead of entities
3. **Framework Coupling** - Domain depending on framework specifics
4. **Database-Driven Design** - Letting database schema drive domain design
5. **Circular Dependencies** - Layers depending on each other