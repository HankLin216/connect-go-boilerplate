FROM golang:latest AS builder

ARG ENVIRONMENT=Development
ARG GOPROXY=https://proxy.golang.org,direct
ENV APP_ENV=${ENVIRONMENT}
# Use the public Go module mirror first so vanity imports do not require direct host resolution.
ENV GOPROXY=${GOPROXY}

# Copy self-signed certificate if it exists and update trust store
COPY certs/ /usr/local/share/ca-certificates/
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates || true

RUN apt-get install -y protobuf-compiler curl \
    && go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
    && go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest \
    && curl -sSL "https://github.com/bufbuild/buf/releases/latest/download/buf-$(uname -s)-$(uname -m)" -o "/usr/local/bin/buf" \
    && chmod +x "/usr/local/bin/buf" \
    && export PATH="$PATH:$(go env GOPATH)/bin"

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN if [ "$APP_ENV" = "Development" ]; then \
    make dev-all; \
    else \
    make all; \
    fi

FROM ubuntu:latest

WORKDIR /app

COPY --from=builder /app/bin .

# The default config.yaml uses 9000 for HTTP server.
EXPOSE 9000

CMD ["./app"]