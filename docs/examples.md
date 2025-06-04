# Examples and Patterns

This document provides practical examples of common patterns and use cases in the template.

## Complete Feature Example: Order Management

Let's walk through implementing a complete order management feature using Clean Architecture.

### 1. Domain Layer

#### Entity: Order
```go
// internal/domain/entities/order.go
package entities

import (
    "errors"
    "time"
)

var (
    ErrEmptyOrder      = errors.New("order must contain at least one item")
    ErrInvalidQuantity = errors.New("quantity must be positive")
)

type OrderID string

type Order struct {
    ID         OrderID
    CustomerID string
    Items      []OrderItem
    Status     OrderStatus
    Total      Money
    CreatedAt  time.Time
    UpdatedAt  time.Time
}

type OrderItem struct {
    ProductID   string
    ProductName string
    Quantity    int
    UnitPrice   Money
}

func NewOrder(customerID string, items []OrderItem) (*Order, error) {
    if len(items) == 0 {
        return nil, ErrEmptyOrder
    }
    
    for _, item := range items {
        if item.Quantity <= 0 {
            return nil, ErrInvalidQuantity
        }
    }
    
    order := &Order{
        ID:         OrderID(generateUUID()),
        CustomerID: customerID,
        Items:      items,
        Status:     OrderStatusPending,
        CreatedAt:  time.Now(),
        UpdatedAt:  time.Now(),
    }
    
    order.Total = order.calculateTotal()
    return order, nil
}

func (o *Order) calculateTotal() Money {
    var total Money
    for _, item := range o.Items {
        itemTotal := item.UnitPrice.Multiply(item.Quantity)
        total = total.Add(itemTotal)
    }
    return total
}

func (o *Order) Confirm() error {
    if o.Status != OrderStatusPending {
        return errors.New("only pending orders can be confirmed")
    }
    o.Status = OrderStatusConfirmed
    o.UpdatedAt = time.Now()
    return nil
}

func (o *Order) Cancel() error {
    if o.Status == OrderStatusDelivered {
        return errors.New("delivered orders cannot be cancelled")
    }
    o.Status = OrderStatusCancelled
    o.UpdatedAt = time.Now()
    return nil
}
```

#### Value Object: Money
```go
// internal/domain/valueobjects/money.go
package valueobjects

import (
    "errors"
    "fmt"
)

type Money struct {
    Amount   int64  // Store as cents to avoid float precision issues
    Currency string
}

func NewMoney(amount float64, currency string) Money {
    return Money{
        Amount:   int64(amount * 100),
        Currency: currency,
    }
}

func (m Money) Add(other Money) Money {
    if m.Currency != other.Currency {
        panic("cannot add money with different currencies")
    }
    return Money{
        Amount:   m.Amount + other.Amount,
        Currency: m.Currency,
    }
}

func (m Money) Multiply(quantity int) Money {
    return Money{
        Amount:   m.Amount * int64(quantity),
        Currency: m.Currency,
    }
}

func (m Money) String() string {
    return fmt.Sprintf("%.2f %s", float64(m.Amount)/100, m.Currency)
}
```

#### Repository Interface
```go
// internal/domain/repositories/order_repository.go
package repositories

import (
    "context"
    "github.com/yourusername/myapp/internal/domain/entities"
)

type OrderRepository interface {
    Save(ctx context.Context, order *entities.Order) error
    FindByID(ctx context.Context, id entities.OrderID) (*entities.Order, error)
    FindByCustomerID(ctx context.Context, customerID string) ([]*entities.Order, error)
    Update(ctx context.Context, order *entities.Order) error
}
```

### 2. Use Cases Layer

#### Command: Place Order
```go
// internal/usecases/commands/place_order.go
package commands

import (
    "context"
    "github.com/yourusername/myapp/internal/domain/entities"
    "github.com/yourusername/myapp/internal/domain/repositories"
)

type PlaceOrderInput struct {
    CustomerID string
    Items      []OrderItemInput
}

type OrderItemInput struct {
    ProductID   string
    ProductName string
    Quantity    int
    UnitPrice   float64
    Currency    string
}

type PlaceOrderOutput struct {
    OrderID   string
    Total     string
    Status    string
    CreatedAt time.Time
}

type PlaceOrderCommand struct {
    orderRepo    repositories.OrderRepository
    productRepo  repositories.ProductRepository
    eventBus     EventPublisher
}

func NewPlaceOrderCommand(
    orderRepo repositories.OrderRepository,
    productRepo repositories.ProductRepository,
    eventBus EventPublisher,
) *PlaceOrderCommand {
    return &PlaceOrderCommand{
        orderRepo:   orderRepo,
        productRepo: productRepo,
        eventBus:    eventBus,
    }
}

func (c *PlaceOrderCommand) Execute(ctx context.Context, input PlaceOrderInput) (*PlaceOrderOutput, error) {
    // Convert input to domain entities
    var items []entities.OrderItem
    for _, item := range input.Items {
        // Verify product exists and has sufficient stock
        product, err := c.productRepo.FindByID(ctx, item.ProductID)
        if err != nil {
            return nil, fmt.Errorf("product not found: %s", item.ProductID)
        }
        
        if product.Stock < item.Quantity {
            return nil, fmt.Errorf("insufficient stock for product: %s", item.ProductID)
        }
        
        items = append(items, entities.OrderItem{
            ProductID:   item.ProductID,
            ProductName: item.ProductName,
            Quantity:    item.Quantity,
            UnitPrice:   entities.NewMoney(item.UnitPrice, item.Currency),
        })
    }
    
    // Create order
    order, err := entities.NewOrder(input.CustomerID, items)
    if err != nil {
        return nil, fmt.Errorf("failed to create order: %w", err)
    }
    
    // Save order
    if err := c.orderRepo.Save(ctx, order); err != nil {
        return nil, fmt.Errorf("failed to save order: %w", err)
    }
    
    // Update product stock
    for _, item := range order.Items {
        if err := c.productRepo.DecrementStock(ctx, item.ProductID, item.Quantity); err != nil {
            // In real app, this should be in a transaction
            return nil, fmt.Errorf("failed to update stock: %w", err)
        }
    }
    
    // Publish event
    c.eventBus.Publish(OrderPlacedEvent{
        OrderID:    string(order.ID),
        CustomerID: order.CustomerID,
        Total:      order.Total.String(),
        Timestamp:  time.Now(),
    })
    
    return &PlaceOrderOutput{
        OrderID:   string(order.ID),
        Total:     order.Total.String(),
        Status:    string(order.Status),
        CreatedAt: order.CreatedAt,
    }, nil
}
```

#### Query: Get Order
```go
// internal/usecases/queries/get_order.go
package queries

import (
    "context"
    "errors"
    "github.com/yourusername/myapp/internal/domain/entities"
    "github.com/yourusername/myapp/internal/domain/repositories"
)

type GetOrderInput struct {
    OrderID string
}

type GetOrderOutput struct {
    OrderID    string
    CustomerID string
    Items      []OrderItemOutput
    Total      string
    Status     string
    CreatedAt  time.Time
    UpdatedAt  time.Time
}

type OrderItemOutput struct {
    ProductID   string
    ProductName string
    Quantity    int
    UnitPrice   string
    Subtotal    string
}

type GetOrderQuery struct {
    orderRepo repositories.OrderRepository
}

func NewGetOrderQuery(orderRepo repositories.OrderRepository) *GetOrderQuery {
    return &GetOrderQuery{orderRepo: orderRepo}
}

func (q *GetOrderQuery) Execute(ctx context.Context, input GetOrderInput) (*GetOrderOutput, error) {
    order, err := q.orderRepo.FindByID(ctx, entities.OrderID(input.OrderID))
    if err != nil {
        if errors.Is(err, repositories.ErrNotFound) {
            return nil, errors.New("order not found")
        }
        return nil, fmt.Errorf("failed to get order: %w", err)
    }
    
    // Convert to output
    output := &GetOrderOutput{
        OrderID:    string(order.ID),
        CustomerID: order.CustomerID,
        Total:      order.Total.String(),
        Status:     string(order.Status),
        CreatedAt:  order.CreatedAt,
        UpdatedAt:  order.UpdatedAt,
    }
    
    for _, item := range order.Items {
        output.Items = append(output.Items, OrderItemOutput{
            ProductID:   item.ProductID,
            ProductName: item.ProductName,
            Quantity:    item.Quantity,
            UnitPrice:   item.UnitPrice.String(),
            Subtotal:    item.UnitPrice.Multiply(item.Quantity).String(),
        })
    }
    
    return output, nil
}
```

### 3. Adapters Layer

#### HTTP Handler
```go
// internal/adapters/http/order_handler.go
package http

import (
    "encoding/json"
    "net/http"
    "github.com/gorilla/mux"
    "github.com/yourusername/myapp/internal/usecases/commands"
    "github.com/yourusername/myapp/internal/usecases/queries"
)

type OrderHandler struct {
    placeOrder *commands.PlaceOrderCommand
    getOrder   *queries.GetOrderQuery
}

func NewOrderHandler(placeOrder *commands.PlaceOrderCommand, getOrder *queries.GetOrderQuery) *OrderHandler {
    return &OrderHandler{
        placeOrder: placeOrder,
        getOrder:   getOrder,
    }
}

func (h *OrderHandler) RegisterRoutes(router *mux.Router) {
    router.HandleFunc("/orders", h.CreateOrder).Methods("POST")
    router.HandleFunc("/orders/{id}", h.GetOrder).Methods("GET")
}

// CreateOrder handles POST /orders
func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
    var req CreateOrderRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondWithError(w, http.StatusBadRequest, "Invalid request body")
        return
    }
    
    // Validate request
    if err := req.Validate(); err != nil {
        respondWithError(w, http.StatusBadRequest, err.Error())
        return
    }
    
    // Convert to use case input
    input := commands.PlaceOrderInput{
        CustomerID: req.CustomerID,
    }
    
    for _, item := range req.Items {
        input.Items = append(input.Items, commands.OrderItemInput{
            ProductID:   item.ProductID,
            ProductName: item.ProductName,
            Quantity:    item.Quantity,
            UnitPrice:   item.UnitPrice,
            Currency:    item.Currency,
        })
    }
    
    // Execute use case
    output, err := h.placeOrder.Execute(r.Context(), input)
    if err != nil {
        // Handle domain errors appropriately
        switch {
        case errors.Is(err, entities.ErrInvalidQuantity):
            respondWithError(w, http.StatusBadRequest, err.Error())
        default:
            respondWithError(w, http.StatusInternalServerError, "Failed to create order")
        }
        return
    }
    
    // Convert to response
    resp := CreateOrderResponse{
        OrderID:   output.OrderID,
        Total:     output.Total,
        Status:    output.Status,
        CreatedAt: output.CreatedAt,
    }
    
    respondWithJSON(w, http.StatusCreated, resp)
}

// GetOrder handles GET /orders/{id}
func (h *OrderHandler) GetOrder(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    orderID := vars["id"]
    
    input := queries.GetOrderInput{OrderID: orderID}
    
    output, err := h.getOrder.Execute(r.Context(), input)
    if err != nil {
        if strings.Contains(err.Error(), "not found") {
            respondWithError(w, http.StatusNotFound, "Order not found")
        } else {
            respondWithError(w, http.StatusInternalServerError, "Failed to get order")
        }
        return
    }
    
    respondWithJSON(w, http.StatusOK, output)
}
```

### 4. Infrastructure Layer

#### Repository Implementation
```go
// internal/infrastructure/database/postgres_order_repository.go
package database

import (
    "context"
    "database/sql"
    "encoding/json"
    "github.com/yourusername/myapp/internal/domain/entities"
    "github.com/yourusername/myapp/internal/domain/repositories"
)

type PostgresOrderRepository struct {
    db *sql.DB
}

func NewPostgresOrderRepository(db *sql.DB) *PostgresOrderRepository {
    return &PostgresOrderRepository{db: db}
}

func (r *PostgresOrderRepository) Save(ctx context.Context, order *entities.Order) error {
    // Serialize items as JSON
    itemsJSON, err := json.Marshal(order.Items)
    if err != nil {
        return err
    }
    
    query := `
        INSERT INTO orders (id, customer_id, items, total_amount, total_currency, status, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `
    
    _, err = r.db.ExecContext(ctx, query,
        order.ID,
        order.CustomerID,
        itemsJSON,
        order.Total.Amount,
        order.Total.Currency,
        order.Status,
        order.CreatedAt,
        order.UpdatedAt,
    )
    
    return err
}

func (r *PostgresOrderRepository) FindByID(ctx context.Context, id entities.OrderID) (*entities.Order, error) {
    query := `
        SELECT id, customer_id, items, total_amount, total_currency, status, created_at, updated_at
        FROM orders
        WHERE id = $1
    `
    
    var order entities.Order
    var itemsJSON []byte
    
    err := r.db.QueryRowContext(ctx, query, id).Scan(
        &order.ID,
        &order.CustomerID,
        &itemsJSON,
        &order.Total.Amount,
        &order.Total.Currency,
        &order.Status,
        &order.CreatedAt,
        &order.UpdatedAt,
    )
    
    if err == sql.ErrNoRows {
        return nil, repositories.ErrNotFound
    }
    if err != nil {
        return nil, err
    }
    
    // Deserialize items
    if err := json.Unmarshal(itemsJSON, &order.Items); err != nil {
        return nil, err
    }
    
    return &order, nil
}

func (r *PostgresOrderRepository) Update(ctx context.Context, order *entities.Order) error {
    itemsJSON, err := json.Marshal(order.Items)
    if err != nil {
        return err
    }
    
    query := `
        UPDATE orders
        SET customer_id = $2, items = $3, total_amount = $4, total_currency = $5, 
            status = $6, updated_at = $7
        WHERE id = $1
    `
    
    result, err := r.db.ExecContext(ctx, query,
        order.ID,
        order.CustomerID,
        itemsJSON,
        order.Total.Amount,
        order.Total.Currency,
        order.Status,
        order.UpdatedAt,
    )
    
    if err != nil {
        return err
    }
    
    rowsAffected, err := result.RowsAffected()
    if err != nil {
        return err
    }
    
    if rowsAffected == 0 {
        return repositories.ErrNotFound
    }
    
    return nil
}
```

### 5. Wiring It All Together

#### Main Application
```go
// cmd/api/main.go
package main

import (
    "database/sql"
    "log"
    "net/http"
    
    "github.com/gorilla/mux"
    _ "github.com/lib/pq"
    
    httpHandlers "github.com/yourusername/myapp/internal/adapters/http"
    "github.com/yourusername/myapp/internal/infrastructure/database"
    "github.com/yourusername/myapp/internal/usecases/commands"
    "github.com/yourusername/myapp/internal/usecases/queries"
)

func main() {
    // Setup database
    db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    defer db.Close()
    
    // Setup repositories
    orderRepo := database.NewPostgresOrderRepository(db)
    productRepo := database.NewPostgresProductRepository(db)
    
    // Setup event bus
    eventBus := NewInMemoryEventBus()
    
    // Setup use cases
    placeOrderCmd := commands.NewPlaceOrderCommand(orderRepo, productRepo, eventBus)
    getOrderQuery := queries.NewGetOrderQuery(orderRepo)
    
    // Setup handlers
    orderHandler := httpHandlers.NewOrderHandler(placeOrderCmd, getOrderQuery)
    
    // Setup router
    router := mux.NewRouter()
    orderHandler.RegisterRoutes(router)
    
    // Add middleware
    router.Use(loggingMiddleware)
    router.Use(authMiddleware)
    
    // Start server
    log.Println("Server starting on port 8080...")
    if err := http.ListenAndServe(":8080", router); err != nil {
        log.Fatal("Server failed to start:", err)
    }
}
```

## Common Patterns

### 1. Error Handling Pattern

```go
// Domain error types
type DomainError struct {
    Code    string
    Message string
}

func (e DomainError) Error() string {
    return e.Message
}

// Predefined errors
var (
    ErrNotFound = DomainError{Code: "NOT_FOUND", Message: "resource not found"}
    ErrUnauthorized = DomainError{Code: "UNAUTHORIZED", Message: "unauthorized access"}
)

// In HTTP handler
func handleError(w http.ResponseWriter, err error) {
    var domainErr DomainError
    if errors.As(err, &domainErr) {
        switch domainErr.Code {
        case "NOT_FOUND":
            respondWithError(w, http.StatusNotFound, domainErr.Message)
        case "UNAUTHORIZED":
            respondWithError(w, http.StatusUnauthorized, domainErr.Message)
        default:
            respondWithError(w, http.StatusBadRequest, domainErr.Message)
        }
        return
    }
    
    // Log internal errors
    log.Printf("Internal error: %v", err)
    respondWithError(w, http.StatusInternalServerError, "Internal server error")
}
```

### 2. Transaction Pattern

```go
// Transaction interface
type Transaction interface {
    Commit() error
    Rollback() error
}

// Unit of Work pattern
type UnitOfWork interface {
    Begin(ctx context.Context) (Transaction, error)
    OrderRepository(tx Transaction) repositories.OrderRepository
    ProductRepository(tx Transaction) repositories.ProductRepository
}

// In use case
func (c *PlaceOrderCommand) Execute(ctx context.Context, input PlaceOrderInput) error {
    tx, err := c.uow.Begin(ctx)
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    orderRepo := c.uow.OrderRepository(tx)
    productRepo := c.uow.ProductRepository(tx)
    
    // Do work with repositories
    // ...
    
    return tx.Commit()
}
```

### 3. Specification Pattern

```go
// Specification interface
type Specification interface {
    IsSatisfiedBy(order *Order) bool
}

// Composite specifications
type AndSpecification struct {
    specs []Specification
}

func (s AndSpecification) IsSatisfiedBy(order *Order) bool {
    for _, spec := range s.specs {
        if !spec.IsSatisfiedBy(order) {
            return false
        }
    }
    return true
}

// Concrete specification
type MinimumOrderAmountSpec struct {
    minAmount Money
}

func (s MinimumOrderAmountSpec) IsSatisfiedBy(order *Order) bool {
    return order.Total.Amount >= s.minAmount.Amount
}

// Usage
spec := AndSpecification{
    specs: []Specification{
        MinimumOrderAmountSpec{minAmount: NewMoney(10.00, "USD")},
        CustomerCreditSpec{customerID: order.CustomerID},
    },
}

if !spec.IsSatisfiedBy(order) {
    return errors.New("order does not meet requirements")
}
```

### 4. Event-Driven Pattern

```go
// Event interface
type Event interface {
    EventName() string
    OccurredAt() time.Time
}

// Domain event
type OrderPlacedEvent struct {
    OrderID    string
    CustomerID string
    Total      string
    Timestamp  time.Time
}

func (e OrderPlacedEvent) EventName() string {
    return "order.placed"
}

func (e OrderPlacedEvent) OccurredAt() time.Time {
    return e.Timestamp
}

// Event handler
type EventHandler interface {
    Handle(ctx context.Context, event Event) error
}

// Email notification handler
type OrderEmailHandler struct {
    emailService EmailService
}

func (h *OrderEmailHandler) Handle(ctx context.Context, event Event) error {
    if e, ok := event.(OrderPlacedEvent); ok {
        return h.emailService.SendOrderConfirmation(ctx, e.CustomerID, e.OrderID)
    }
    return nil
}
```

## Testing Patterns

### 1. Mock Repository

```go
// Mock repository for testing
type MockOrderRepository struct {
    mock.Mock
}

func (m *MockOrderRepository) Save(ctx context.Context, order *entities.Order) error {
    args := m.Called(ctx, order)
    return args.Error(0)
}

func (m *MockOrderRepository) FindByID(ctx context.Context, id entities.OrderID) (*entities.Order, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*entities.Order), args.Error(1)
}

// Usage in test
func TestPlaceOrder_Success(t *testing.T) {
    // Arrange
    mockRepo := new(MockOrderRepository)
    mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Order")).Return(nil)
    
    useCase := NewPlaceOrderCommand(mockRepo, mockProductRepo, mockEventBus)
    
    // Act
    output, err := useCase.Execute(context.Background(), input)
    
    // Assert
    assert.NoError(t, err)
    assert.NotEmpty(t, output.OrderID)
    mockRepo.AssertExpectations(t)
}
```

### 2. Builder Pattern for Tests

```go
// Test data builder
type OrderBuilder struct {
    order *entities.Order
}

func NewOrderBuilder() *OrderBuilder {
    return &OrderBuilder{
        order: &entities.Order{
            ID:         "test-order-1",
            CustomerID: "customer-1",
            Status:     entities.OrderStatusPending,
            CreatedAt:  time.Now(),
            UpdatedAt:  time.Now(),
        },
    }
}

func (b *OrderBuilder) WithCustomerID(id string) *OrderBuilder {
    b.order.CustomerID = id
    return b
}

func (b *OrderBuilder) WithItems(items []entities.OrderItem) *OrderBuilder {
    b.order.Items = items
    b.order.Total = b.order.calculateTotal()
    return b
}

func (b *OrderBuilder) WithStatus(status entities.OrderStatus) *OrderBuilder {
    b.order.Status = status
    return b
}

func (b *OrderBuilder) Build() *entities.Order {
    return b.order
}

// Usage
order := NewOrderBuilder().
    WithCustomerID("customer-123").
    WithItems([]entities.OrderItem{
        {ProductID: "prod-1", Quantity: 2, UnitPrice: NewMoney(10.00, "USD")},
    }).
    Build()
```

This completes the comprehensive example of implementing a feature using Clean Architecture principles.