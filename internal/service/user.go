package service

import (
	"context"

	"connectrpc.com/connect"
	v1 "github.com/HankLin216/connect-go-boilerplate/api/user/v1"
	"github.com/HankLin216/connect-go-boilerplate/internal/biz"
)

// UserService is a user service.
type UserService struct {
	uc *biz.UserUsecase
}

// NewUserService new a user service.
func NewUserService(uc *biz.UserUsecase) *UserService {
	return &UserService{uc: uc}
}

// Get implements Connect-Go UserHandler interface
func (s *UserService) Get(ctx context.Context, req *connect.Request[v1.GetRequest]) (*connect.Response[v1.GetResponse], error) {
	user, err := s.uc.GetUser(ctx, req.Msg.Name)
	if err != nil {
		// If user not found, return friendly message instead of error
		resp := connect.NewResponse(&v1.GetResponse{
			Message: "User " + req.Msg.Name + " not found, but hello anyway!",
		})
		// Set shorter cache time for error responses
		resp.Header().Set("Cache-Control", "public, max-age=5")
		return resp, nil
	}

	resp := connect.NewResponse(&v1.GetResponse{
		Message: "Hello " + user.Name + ", your email is " + user.Email,
	})

	// Set cache response headers, compliant with RFC 7234 standard
	// public: indicates that response may be cached by any cache (including proxies)
	// max-age=30: response is valid for 30 seconds
	resp.Header().Set("Cache-Control", "public, max-age=30")

	// Add ETag for conditional requests
	resp.Header().Set("ETag", "\"user-"+user.Name+"-v1\"")

	// Set Last-Modified (simulate user last modification time)
	resp.Header().Set("Last-Modified", "Mon, 11 Nov 2024 08:00:00 GMT")

	return resp, nil
}
