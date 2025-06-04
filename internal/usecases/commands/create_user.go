// Package commands contains write operations that modify system state.
package commands

import (
	"context"
	"fmt"

	"gotemplaterepo/internal/domain/entities"
	"gotemplaterepo/internal/domain/repositories"
)

// CreateUserCommand represents the input for creating a new user.
type CreateUserCommand struct {
	Username string
	Email    string
}

// CreateUserHandler handles user creation commands.
type CreateUserHandler struct {
	userRepo repositories.UserRepository
	idGen    IDGenerator
}

// IDGenerator defines the interface for generating unique IDs.
type IDGenerator interface {
	Generate() string
}

// NewCreateUserHandler creates a new CreateUserHandler instance.
func NewCreateUserHandler(userRepo repositories.UserRepository, idGen IDGenerator) *CreateUserHandler {
	return &CreateUserHandler{
		userRepo: userRepo,
		idGen:    idGen,
	}
}

// Handle executes the create user command.
func (h *CreateUserHandler) Handle(ctx context.Context, cmd CreateUserCommand) (*entities.User, error) {
	existingUser, err := h.userRepo.GetByEmail(ctx, cmd.Email)
	if err == nil && existingUser != nil {
		return nil, entities.ErrUserAlreadyExists
	}

	existingUser, err = h.userRepo.GetByUsername(ctx, cmd.Username)
	if err == nil && existingUser != nil {
		return nil, entities.ErrUserAlreadyExists
	}

	userID, err := entities.NewUserID(h.idGen.Generate())
	if err != nil {
		return nil, fmt.Errorf("failed to generate user ID: %w", err)
	}

	user, err := entities.NewUser(userID, cmd.Username, cmd.Email)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	if err := h.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("failed to save user: %w", err)
	}

	return user, nil
}
