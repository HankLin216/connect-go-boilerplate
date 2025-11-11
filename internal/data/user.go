package data

import (
	"context"

	"github.com/HankLin216/connect-go-boilerplate/internal/biz"
)

type userRepo struct {
	data *Data
}

// NewUserRepo .
func NewUserRepo(data *Data) biz.UserRepo {
	return &userRepo{
		data: data,
	}
}

func (r *userRepo) Save(ctx context.Context, u *biz.User) (*biz.User, error) {
	return nil, nil
}

func (r *userRepo) Update(ctx context.Context, u *biz.User) (*biz.User, error) {
	return nil, nil
}

func (r *userRepo) FindByID(ctx context.Context, id int64) (*biz.User, error) {
	return nil, nil
}

func (r *userRepo) FindByName(ctx context.Context, name string) (*biz.User, error) {
	return nil, nil
}

func (r *userRepo) ListAll(ctx context.Context) ([]*biz.User, error) {
	return nil, nil
}

func (r *userRepo) Delete(ctx context.Context, id int64) error {
	return nil
}
