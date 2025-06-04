#!/bin/bash
# Create a new use case (command or query)

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <command|query> <UseCaseName>"
    echo "Example: $0 command CreateProduct"
    echo "Example: $0 query GetProductById"
    exit 1
fi

TYPE=$1
USECASE_NAME=$2
USECASE_NAME_SNAKE=$(echo "$USECASE_NAME" | sed 's/\([A-Z]\)/_\1/g' | tr '[:upper:]' '[:lower:]' | sed 's/^_//')

if [ "$TYPE" != "command" ] && [ "$TYPE" != "query" ]; then
    echo "Error: Type must be either 'command' or 'query'"
    exit 1
fi

PLURAL_TYPE="${TYPE}s"

# Create use case file
cat > "internal/usecases/${PLURAL_TYPE}/${USECASE_NAME_SNAKE}.go" << EOF
package ${PLURAL_TYPE}

import (
    "context"
)

// ${USECASE_NAME}Input represents the input for ${USECASE_NAME}
type ${USECASE_NAME}Input struct {
    // Add input fields here
}

// ${USECASE_NAME}Output represents the output for ${USECASE_NAME}
type ${USECASE_NAME}Output struct {
    // Add output fields here
}

// ${USECASE_NAME} handles the ${USECASE_NAME_SNAKE} use case
type ${USECASE_NAME} struct {
    // Add dependencies here (repositories, services, etc.)
}

// New${USECASE_NAME} creates a new ${USECASE_NAME} instance
func New${USECASE_NAME}() *${USECASE_NAME} {
    return &${USECASE_NAME}{
        // Initialize dependencies
    }
}

// Execute executes the ${USECASE_NAME} use case
func (uc *${USECASE_NAME}) Execute(ctx context.Context, input ${USECASE_NAME}Input) (*${USECASE_NAME}Output, error) {
    // Implement use case logic here
    
    return &${USECASE_NAME}Output{}, nil
}
EOF

# Create use case test file
cat > "internal/usecases/${PLURAL_TYPE}/${USECASE_NAME_SNAKE}_test.go" << EOF
package ${PLURAL_TYPE}

import (
    "context"
    "testing"
)

func TestNew${USECASE_NAME}(t *testing.T) {
    uc := New${USECASE_NAME}()
    if uc == nil {
        t.Error("expected use case instance, got nil")
    }
}

func Test${USECASE_NAME}_Execute(t *testing.T) {
    tests := []struct {
        name    string
        input   ${USECASE_NAME}Input
        wantErr bool
    }{
        {
            name:    "successful execution",
            input:   ${USECASE_NAME}Input{},
            wantErr: false,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            uc := New${USECASE_NAME}()
            _, err := uc.Execute(context.Background(), tt.input)
            
            if (err != nil) != tt.wantErr {
                t.Errorf("Execute() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
EOF

echo "Created use case: internal/usecases/${PLURAL_TYPE}/${USECASE_NAME_SNAKE}.go"
echo "Created tests: internal/usecases/${PLURAL_TYPE}/${USECASE_NAME_SNAKE}_test.go"
echo ""
echo "Next steps:"
echo "1. Define input and output structures"
echo "2. Add repository dependencies"
echo "3. Implement the Execute method"
echo "4. Add test cases"
echo "5. Run: make test"