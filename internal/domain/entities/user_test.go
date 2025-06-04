package entities_test

import (
	"testing"
	"time"
	
	"gotemplaterepo/internal/domain/entities"
)

func TestNewUser(t *testing.T) {
	tests := []struct {
		name     string
		id       entities.UserID
		username string
		email    string
		wantErr  error
	}{
		{
			name:     "valid user",
			id:       "user123",
			username: "johndoe",
			email:    "john@example.com",
			wantErr:  nil,
		},
		{
			name:     "empty username",
			id:       "user123",
			username: "",
			email:    "john@example.com",
			wantErr:  entities.ErrInvalidUsername,
		},
		{
			name:     "short username",
			id:       "user123",
			username: "jo",
			email:    "john@example.com",
			wantErr:  entities.ErrInvalidUsername,
		},
		{
			name:     "empty email",
			id:       "user123",
			username: "johndoe",
			email:    "",
			wantErr:  entities.ErrInvalidEmail,
		},
		{
			name:     "short email",
			id:       "user123",
			username: "johndoe",
			email:    "j@ex",
			wantErr:  entities.ErrInvalidEmail,
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			user, err := entities.NewUser(tt.id, tt.username, tt.email)
			
			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("NewUser() error = %v, wantErr %v", err, tt.wantErr)
				}
				return
			}
			
			if err != nil {
				t.Errorf("NewUser() unexpected error = %v", err)
				return
			}
			
			if user.ID != tt.id {
				t.Errorf("NewUser() ID = %v, want %v", user.ID, tt.id)
			}
			
			if user.Username != tt.username {
				t.Errorf("NewUser() Username = %v, want %v", user.Username, tt.username)
			}
			
			if user.Email != tt.email {
				t.Errorf("NewUser() Email = %v, want %v", user.Email, tt.email)
			}
			
			if user.CreatedAt.IsZero() {
				t.Error("NewUser() CreatedAt should not be zero")
			}
			
			if user.UpdatedAt.IsZero() {
				t.Error("NewUser() UpdatedAt should not be zero")
			}
		})
	}
}

func TestUser_UpdateEmail(t *testing.T) {
	user, _ := entities.NewUser("user123", "johndoe", "john@example.com")
	originalUpdatedAt := user.UpdatedAt
	
	time.Sleep(10 * time.Millisecond)
	
	tests := []struct {
		name    string
		email   string
		wantErr error
	}{
		{
			name:    "valid email",
			email:   "newemail@example.com",
			wantErr: nil,
		},
		{
			name:    "empty email",
			email:   "",
			wantErr: entities.ErrInvalidEmail,
		},
		{
			name:    "short email",
			email:   "a@b",
			wantErr: entities.ErrInvalidEmail,
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := user.UpdateEmail(tt.email)
			
			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("UpdateEmail() error = %v, wantErr %v", err, tt.wantErr)
				}
				return
			}
			
			if err != nil {
				t.Errorf("UpdateEmail() unexpected error = %v", err)
				return
			}
			
			if user.Email != tt.email {
				t.Errorf("UpdateEmail() Email = %v, want %v", user.Email, tt.email)
			}
			
			if !user.UpdatedAt.After(originalUpdatedAt) {
				t.Error("UpdateEmail() should update UpdatedAt")
			}
		})
	}
}