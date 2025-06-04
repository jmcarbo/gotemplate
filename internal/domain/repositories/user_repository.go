package repositories

import (
	"context"
	
	"github.com/jmca/selektor/internal/domain/entities"
)

type UserRepository interface {
	Create(ctx context.Context, user *entities.User) error
	GetByID(ctx context.Context, id entities.UserID) (*entities.User, error)
	GetByEmail(ctx context.Context, email string) (*entities.User, error)
	GetByUsername(ctx context.Context, username string) (*entities.User, error)
	Update(ctx context.Context, user *entities.User) error
	Delete(ctx context.Context, id entities.UserID) error
	List(ctx context.Context, offset, limit int) ([]*entities.User, error)
	Count(ctx context.Context) (int64, error)
}