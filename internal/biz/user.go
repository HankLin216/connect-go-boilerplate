package biz

import (
	"context"

	"github.com/HankLin216/go-utils/log"
	"go.uber.org/zap"
)

// User is a User model.
type User struct {
	ID    int64  `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	Age   int32  `json:"age"`
}

// UserRepo is a User repo.
type UserRepo interface {
	Save(context.Context, *User) (*User, error)
	Update(context.Context, *User) (*User, error)
	FindByID(context.Context, int64) (*User, error)
	FindByName(context.Context, string) (*User, error)
	ListAll(context.Context) ([]*User, error)
	Delete(context.Context, int64) error
}

// UserUsecase is a User usecase.
type UserUsecase struct {
	repo UserRepo
}

// NewUserUsecase new a User usecase.
func NewUserUsecase(repo UserRepo) *UserUsecase {
	return &UserUsecase{repo: repo}
}

// GetUser gets a User by name.
func (uc *UserUsecase) GetUser(ctx context.Context, name string) (*User, error) {
	log.Info("GetUser", zap.String("name", name))
	u := &User{
		Name: name,
	}
	return u, nil
}
