# Development Guide

This guide covers the development workflow, tools, and best practices for working with this template.

## Development Setup

### Required Tools

1. **Go 1.23+** - The programming language
2. **Docker & Docker Compose** - For running services locally
3. **Make** - Build automation
4. **Git** - Version control
5. **Pre-commit** - Git hooks framework
6. **Your favorite IDE** - VS Code, GoLand, Vim, etc.

### Initial Setup

```bash
# Install all development tools
make install-tools

# Install pre-commit hooks
./scripts/install-hooks.sh

# Create your .env file
cp .env.example .env

# Start dependencies (database, redis, etc.)
docker-compose up -d

# Verify everything works
make lint
make test
```

## Development Workflow

### 1. Starting Development

```bash
# Start the development server with hot reload
make dev

# Or run manually
make run

# Or use Docker
make docker-run
```

### 2. Creating New Features

#### Step 1: Domain Modeling
```bash
# Create a new entity
# Use Claude Code: /create-entity Order

# Create value objects
# Use Claude Code: /add-valueobject OrderStatus
```

#### Step 2: Business Logic
```bash
# Create use cases
# Use Claude Code: /create-usecase command PlaceOrder
# Use Claude Code: /create-usecase query GetOrderById
```

#### Step 3: API Layer
```bash
# Add HTTP endpoints
# Use Claude Code: /add-http-endpoint PlaceOrder

# Or add gRPC service
# Use Claude Code: /add-grpc-service OrderService
```

#### Step 4: Persistence
```bash
# Implement repository
# Use Claude Code: /implement-repository OrderRepository
```

### 3. Testing

#### Running Tests
```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests
make test-integration

# Run with coverage
make test-coverage

# Run specific package tests
go test -v ./internal/domain/entities/...
```

#### Writing Tests

**Unit Test Example**:
```go
func TestOrder_CalculateTotal(t *testing.T) {
    tests := []struct {
        name     string
        items    []OrderItem
        expected Money
    }{
        {
            name: "single item",
            items: []OrderItem{
                {ProductID: "1", Quantity: 2, Price: NewMoney(10.00, "USD")},
            },
            expected: NewMoney(20.00, "USD"),
        },
        {
            name:     "empty order",
            items:    []OrderItem{},
            expected: NewMoney(0, "USD"),
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            order := &Order{Items: tt.items}
            total := order.CalculateTotal()
            
            if !total.Equals(tt.expected) {
                t.Errorf("expected %v, got %v", tt.expected, total)
            }
        })
    }
}
```

**Integration Test Example**:
```go
func TestOrderRepository_Save(t *testing.T) {
    // Setup test database
    db := setupTestDB(t)
    defer db.Close()
    
    repo := NewPostgresOrderRepository(db)
    ctx := context.Background()
    
    // Create test order
    order := &Order{
        ID:         NewOrderID(),
        CustomerID: "customer-1",
        Items:      []OrderItem{{...}},
    }
    
    // Test save
    err := repo.Save(ctx, order)
    require.NoError(t, err)
    
    // Verify by fetching
    saved, err := repo.FindByID(ctx, order.ID)
    require.NoError(t, err)
    assert.Equal(t, order.ID, saved.ID)
}
```

### 4. Code Quality

#### Formatting and Linting
```bash
# Format code
make fmt

# Run linter
make lint

# Fix linting issues
make lint-fix

# Run security scan
make security
```

#### Pre-commit Checks
All commits must pass:
1. Code formatting (gofmt)
2. Import organization (goimports)
3. Linting (golangci-lint)
4. Tests (go test)
5. Commit message format (conventional commits)

### 5. Database Management

#### Migrations
```bash
# Create a new migration
make migrate-create name=add_orders_table

# Run migrations
make migrate-up

# Rollback migrations
make migrate-down

# Check migration status
make migrate-status
```

#### Migration Example:
```sql
-- migrations/001_add_orders_table.up.sql
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);

-- migrations/001_add_orders_table.down.sql
DROP TABLE IF EXISTS orders;
```

## Best Practices

### 1. Domain-Driven Design

- **Rich Domain Models**: Put business logic in entities, not services
- **Value Objects**: Use for concepts without identity
- **Ubiquitous Language**: Use business terms in code
- **Bounded Contexts**: Keep related concepts together

### 2. Error Handling

```go
// Define domain errors
var (
    ErrOrderNotFound = errors.New("order not found")
    ErrInvalidQuantity = errors.New("quantity must be positive")
)

// Wrap errors with context
if err != nil {
    return fmt.Errorf("failed to save order: %w", err)
}

// Custom error types
type ValidationError struct {
    Field   string
    Message string
}

func (e ValidationError) Error() string {
    return fmt.Sprintf("validation error on %s: %s", e.Field, e.Message)
}
```

### 3. Dependency Injection

```go
// Define interface in domain
type OrderRepository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id OrderID) (*Order, error)
}

// Inject in use case
type PlaceOrderCommand struct {
    orderRepo OrderRepository
    eventBus  EventPublisher
}

func NewPlaceOrderCommand(orderRepo OrderRepository, eventBus EventPublisher) *PlaceOrderCommand {
    return &PlaceOrderCommand{
        orderRepo: orderRepo,
        eventBus:  eventBus,
    }
}
```

### 4. Context Usage

Always pass context for:
- Cancellation
- Timeouts
- Request-scoped values

```go
func (uc *GetOrderQuery) Execute(ctx context.Context, orderID string) (*OrderDTO, error) {
    // Set timeout
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    order, err := uc.orderRepo.FindByID(ctx, OrderID(orderID))
    if err != nil {
        return nil, err
    }
    
    return toOrderDTO(order), nil
}
```

### 5. Logging

```go
import "github.com/yourusername/myapp/pkg/logger"

// Structured logging
logger.Info("order created",
    "order_id", order.ID,
    "customer_id", order.CustomerID,
    "total", order.Total,
)

// With context
logger.WithContext(ctx).Error("failed to save order",
    "error", err,
    "order_id", order.ID,
)
```

## Debugging

### Local Debugging

1. **VS Code**:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Launch API",
         "type": "go",
         "request": "launch",
         "mode": "debug",
         "program": "${workspaceFolder}/cmd/api",
         "env": {
           "ENV": "development"
         }
       }
     ]
   }
   ```

2. **Delve**:
   ```bash
   dlv debug ./cmd/api
   ```

### Docker Debugging

```bash
# Build with debug symbols
docker build --target debug -t myapp:debug .

# Run with Delve
docker run -p 8080:8080 -p 2345:2345 myapp:debug
```

## Performance

### Profiling

```go
import _ "net/http/pprof"

// In main.go
go func() {
    log.Println(http.ListenAndServe("localhost:6060", nil))
}()
```

### Benchmarking

```go
func BenchmarkOrder_CalculateTotal(b *testing.B) {
    order := &Order{
        Items: generateItems(100),
    }
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _ = order.CalculateTotal()
    }
}
```

Run benchmarks:
```bash
make benchmark
```

## Continuous Integration

### GitHub Actions Workflow

The template includes CI/CD workflows that:
1. Run on every push and PR
2. Check code formatting
3. Run linter
4. Execute all tests
5. Build Docker image
6. Run security scans

### Local CI Simulation

```bash
# Run full CI pipeline locally
make ci
```

## Troubleshooting

### Common Issues

1. **Import Errors**
   ```bash
   go mod tidy
   go mod download
   ```

2. **Linting Failures**
   ```bash
   make lint-fix
   ```

3. **Test Database Issues**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

4. **Port Already in Use**
   ```bash
   lsof -i :8080
   kill -9 <PID>
   ```

## Resources

- [Effective Go](https://golang.org/doc/effective_go.html)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)