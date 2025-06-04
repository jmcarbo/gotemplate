// Package valueobjects contains value objects for the domain.
package valueobjects

import (
	"errors"
)

// Example value object for testing import updates
type Example struct {
	ID    string
	Value string
}

// NewExample creates a new Example value object
func NewExample(id, value string) (*Example, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}
	if value == "" {
		return nil, errors.New("value cannot be empty")
	}
	return &Example{
		ID:    id,
		Value: value,
	}, nil
}
