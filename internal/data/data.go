package data

import (
	"github.com/HankLin216/connect-go-boilerplate/internal/conf"

	"github.com/google/wire"
	"go.uber.org/zap"
)

// ProviderSet is data providers.
var ProviderSet = wire.NewSet(NewData, NewGreeterRepo)

// Data .
type Data struct {
	// TODO wrapped database client
}

// NewData .
func NewData(c *conf.Data, logger *zap.Logger) (*Data, func(), error) {
	cleanup := func() {
		logger.Info("closing the data resources")
	}
	return &Data{}, cleanup, nil
}
