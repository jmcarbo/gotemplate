// Package valueobjects contains value objects for the domain.
package valueobjects

import (
	"errors"

	"gotemplaterepo/internal/domain/entities"
)

// Example value object for testing import updates
type Example struct {
	UserID entities.UserID
	Value  string
}

// NewExample creates a new Example value object
func NewExample(userID entities.UserID, value string) (*Example, error) {
	if value == "" {
		return nil, errors.New("value cannot be empty")
	}
	return &Example{
		UserID: userID,
		Value:  value,
	}, nil
}
