VERSION=$(shell git describe --tags --always)
YMAL_CONF_PATH=./config.yaml
HARBOR_REGISTRY=192.168.40.185:30003
HARBOR_PROJECT=connect-go-boilerplate

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

.PHONY: restart-service
# usage: make restart-service service=<service_name>
restart-service:
	@if [ -z "$(service)" ]; then \
		echo "Usage: make restart-service service=<service_name>"; \
		exit 1; \
	fi
	VERSION=$(VERSION) docker-compose up -d --no-deps --force-recreate $(service)

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
	docker run -d --rm --name connect-go-boilerplate -p 9000:9000 connect-go-boilerplate:$(VERSION)

.PHONY: dev-run-image
# run development image
dev-run-image:
	docker run -d --rm --name connect-go-boilerplate-dev -p 9000:9000 connect-go-boilerplate:$(VERSION)-dev

.PHONY: full-docker-compose
# build image and run docker-compose
full-docker-compose: build-image
	VERSION=$(VERSION) docker-compose up -d

.PHONY: docker-compose
# run docker-compose without building
docker-compose:
	VERSION=$(VERSION) docker-compose up -d

.PHONY: dev-full-docker-compose
# build dev image and run docker-compose
dev-full-docker-compose: dev-build-image
	VERSION=$(VERSION)-dev docker-compose up -d

.PHONY: dev-docker-compose
# run development docker-compose without building
dev-docker-compose:
	VERSION=$(VERSION)-dev docker-compose up -d

.PHONY: app-docker-compose
# run app stack (app + envoy + keycloak)
app-docker-compose:
	VERSION=$(VERSION) docker-compose up -d connect-go-boilerplate envoy-proxy keycloak

.PHONY: dev-app-docker-compose
# run app stack (app + envoy + keycloak)
dev-app-docker-compose:
	VERSION=$(VERSION)-dev docker-compose up -d connect-go-boilerplate envoy-proxy keycloak

.PHONY: export-realm
# export keycloak realm config to json file
export-realm:
	@echo "Exporting Keycloak realm..."
	@docker exec keycloak /opt/keycloak/bin/kc.sh export --dir /tmp/export --realm connect-go --users realm_file
	@docker cp keycloak:/tmp/export/connect-go-realm.json ./keycloak-realm.json
	@docker exec keycloak rm -rf /tmp/export
	@echo "Realm exported to ./keycloak-realm.json"

.PHONY: helm-install
# install helm chart without building image
helm-install:
	helm upgrade --install connect-go-boilerplate ./helm/connect-go-boilerplate \
	--set connectGoBoilerplate.image.tag=$(VERSION) \
	--set connectGoBoilerplate.image.pullPolicy=Never \
	--create-namespace \
	--namespace connect-go

.PHONY: full-helm-install
# build image and install helm chart
full-helm-install: build-image helm-install

.PHONY: helm-uninstall
# uninstall helm chart
helm-uninstall:
	helm uninstall connect-go-boilerplate --namespace connect-go

.PHONY: build-client
# build simple client
build-client:
	@echo "Building simple client..."
	@go build -o bin/client ./cmd/client

.PHONY: run-client
# run simple client with default settings
run-client: build-client
	@echo "Running simple client..."
	@./bin/client

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