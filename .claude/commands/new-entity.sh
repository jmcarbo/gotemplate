#!/bin/bash
# Create a new domain entity with tests

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <EntityName>"
    echo "Example: $0 Product"
    exit 1
fi

ENTITY_NAME=$1
ENTITY_NAME_LOWER=$(echo "$ENTITY_NAME" | tr '[:upper:]' '[:lower:]')

# Create entity file
cat > "internal/domain/entities/${ENTITY_NAME_LOWER}.go" << EOF
package entities

import (
    "time"
)

// ${ENTITY_NAME} represents a ${ENTITY_NAME_LOWER} in the domain
type ${ENTITY_NAME} struct {
    ID        string
    CreatedAt time.Time
    UpdatedAt time.Time
}

// New${ENTITY_NAME} creates a new ${ENTITY_NAME} instance
func New${ENTITY_NAME}(id string) *${ENTITY_NAME} {
    now := time.Now()
    return &${ENTITY_NAME}{
        ID:        id,
        CreatedAt: now,
        UpdatedAt: now,
    }
}

// Update updates the ${ENTITY_NAME} and sets the UpdatedAt timestamp
func (e *${ENTITY_NAME}) Update() {
    e.UpdatedAt = time.Now()
}
EOF

# Create entity test file
cat > "internal/domain/entities/${ENTITY_NAME_LOWER}_test.go" << EOF
package entities

import (
    "testing"
    "time"
)

func TestNew${ENTITY_NAME}(t *testing.T) {
    id := "test-id"
    entity := New${ENTITY_NAME}(id)

    if entity.ID != id {
        t.Errorf("expected ID %s, got %s", id, entity.ID)
    }

    if entity.CreatedAt.IsZero() {
        t.Error("CreatedAt should not be zero")
    }

    if entity.UpdatedAt.IsZero() {
        t.Error("UpdatedAt should not be zero")
    }
}

func Test${ENTITY_NAME}_Update(t *testing.T) {
    entity := New${ENTITY_NAME}("test-id")
    originalUpdatedAt := entity.UpdatedAt

    time.Sleep(10 * time.Millisecond)
    entity.Update()

    if !entity.UpdatedAt.After(originalUpdatedAt) {
        t.Error("UpdatedAt should be updated after calling Update()")
    }
}
EOF

echo "Created entity: internal/domain/entities/${ENTITY_NAME_LOWER}.go"
echo "Created tests: internal/domain/entities/${ENTITY_NAME_LOWER}_test.go"
echo ""
echo "Next steps:"
echo "1. Add domain-specific fields to the entity"
echo "2. Implement business logic methods"
echo "3. Create a repository interface in internal/domain/repositories/"
echo "4. Run: make test"