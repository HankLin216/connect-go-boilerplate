VERSION=$(shell git describe --tags --always)
YMAL_CONF_PATH=./config.yaml

.PHONY: install
# install golang, buf and related tools
install:
	sudo apt update && \
	sudo apt remove -y golang golang-go golang-src && \
	wget -O- https://golang.org/dl/go1.23.2.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf - && \
	echo 'export PATH="/usr/local/go/bin:$$HOME/go/bin:$$PATH"' >> ~/.bashrc && \
	curl -sSL "https://github.com/bufbuild/buf/releases/latest/download/buf-Linux-x86_64" -o "/tmp/buf" && \
	sudo mv "/tmp/buf" "/usr/local/bin/buf" && \
	sudo chmod +x "/usr/local/bin/buf" && \
	export PATH="/usr/local/go/bin:$$HOME/go/bin:$$PATH" && \
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
	go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest && \
	go version && buf --version && \
	echo "Please run 'source ~/.bashrc' or start a new shell session to update your PATH"

.PHONY: check-env
# check if required tools are available
check-env:
	@echo "Checking required tools..."
	@which go > /dev/null || (echo "❌ go not found in PATH" && exit 1)
	@which buf > /dev/null || (echo "❌ buf not found in PATH" && exit 1)
	@which protoc-gen-go > /dev/null || (echo "❌ protoc-gen-go not found in PATH" && exit 1)
	@which protoc-gen-connect-go > /dev/null || (echo "❌ protoc-gen-connect-go not found in PATH" && exit 1)
	@echo "✅ All required tools are available"

.PHONY: copy-config
# copy config
copy-config:
	mkdir -p ./bin
	cp ./configs/* ./bin/

.PHONY: api
# generate api proto
api:
	@echo "Generating API proto files..."
	@buf generate --path api

.PHONY: config
# generate config proto
config:
	@echo "Generating config proto files..."
	@buf generate --path internal

.PHONY: tidy
# tidy go modules
tidy:
	go mod tidy

.PHONY: generate
# generate wire
generate: tidy
	go generate ./...

.PHONY: build
# build production
build: copy-config
	go build -o ./bin/app -ldflags "-s -w -X main.Version=$(VERSION) -X main.Env=Production -X main.ConfFolderPath=$(YMAL_CONF_PATH)" ./cmd/server

.PHONY: dev-build
# build development
dev-build: copy-config
	go build -o ./bin/app -ldflags "-s -w -X main.Version=$(VERSION) -X main.Env=Development -X main.ConfFolderPath=$(YMAL_CONF_PATH)" ./cmd/server

.PHONY: all
# generate all
all: api config generate build

.PHONY: dev-all
# generate development all
dev-all: api config generate dev-build

.PHONY: build-image
# build production image
build-image:
	docker build --build-arg ENVIRONMENT=Production -t connect-go-boilerplate:$(VERSION) -f Dockerfile .

.PHONY: dev-build-image
# build development image
dev-build-image:
	docker build --build-arg ENVIRONMENT=Development -t connect-go-boilerplate:$(VERSION)-dev -f Dockerfile .

.PHONY: run-image
# run production image
run-image:
	docker run -d --rm --name connect-go-boilerplate -p 8000:8000 connect-go-boilerplate:$(VERSION)

.PHONY: dev-run-image
# run development image
dev-run-image:
	docker run -d --rm --name connect-go-boilerplate-dev -p 8000:8000 connect-go-boilerplate:$(VERSION)-dev

.PHONY: docker-compose
# run docker-compose
docker-compose: build-image
	VERSION=$(VERSION) docker-compose up -d

.PHONY: dev-docker-compose
# run development docker-compose
dev-docker-compose: dev-build-image
	VERSION=$(VERSION)-dev docker-compose up -d

.PHONY: help
# show help
help:
	@echo ''
	@echo 'Usage:'
	@echo ' make [target]'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
	helpMessage = match(lastLine, /^# (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
			printf "\033[36m%-22s\033[0m %s\n", helpCommand,helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help