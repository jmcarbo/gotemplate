// Package entities contains the core business entities of the domain.
package entities

import (
	"errors"
	"time"
)

// Domain errors for user entity.
var (
	ErrInvalidUserID     = errors.New("invalid user ID")
	ErrInvalidEmail      = errors.New("invalid email address")
	ErrInvalidUsername   = errors.New("invalid username")
	ErrUserNotFound      = errors.New("user not found")
	ErrUserAlreadyExists = errors.New("user already exists")
)

// UserID represents a unique identifier for a user.
type UserID string

// NewUserID creates a new UserID with validation.
func NewUserID(id string) (UserID, error) {
	if id == "" {
		return "", ErrInvalidUserID
	}
	return UserID(id), nil
}

// String returns the string representation of UserID.
func (id UserID) String() string {
	return string(id)
}

// User represents a user in the system.
type User struct {
	ID        UserID
	Username  string
	Email     string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// NewUser creates a new User with validation.
func NewUser(id UserID, username, email string) (*User, error) {
	if err := validateUsername(username); err != nil {
		return nil, err
	}

	if err := validateEmail(email); err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	return &User{
		ID:        id,
		Username:  username,
		Email:     email,
		CreatedAt: now,
		UpdatedAt: now,
	}, nil
}

// UpdateEmail updates the user's email address.
func (u *User) UpdateEmail(email string) error {
	if err := validateEmail(email); err != nil {
		return err
	}
	u.Email = email
	u.UpdatedAt = time.Now().UTC()
	return nil
}

// UpdateUsername updates the user's username.
func (u *User) UpdateUsername(username string) error {
	if err := validateUsername(username); err != nil {
		return err
	}
	u.Username = username
	u.UpdatedAt = time.Now().UTC()
	return nil
}

func validateUsername(username string) error {
	if username == "" || len(username) < 3 {
		return ErrInvalidUsername
	}
	return nil
}

func validateEmail(email string) error {
	if email == "" || len(email) < 5 {
		return ErrInvalidEmail
	}
	return nil
}
