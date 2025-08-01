# connect-go-boilerplate
## subtitle
---
## Requirements

### Core Requirements
- **Go 1.23.2+** (for building and running the application)
- **buf** (for generating proto files)
  - Linux: Auto-installed via `make install`
  - Windows: Download from https://github.com/bufbuild/buf/releases and set environment variable

### Protocol Buffers Tools (auto-installed via Go)
- **protoc-gen-go** (Go protocol buffer compiler plugin)
- **protoc-gen-go-grpc** (Go gRPC protocol buffer compiler plugin)

### Optional but Recommended
- **Docker** (for containerization)
- **make** (for Linux build automation)
- **git** (for version tagging in builds)

## Features

- one
- two
- three

## Tech

TODO

- [Something] - for Something!

## Installation
TODO...

## Plugins

| Plugin | README.md |
| ------ | ------ |
| Some | Thing |

## Development
- VSCode Run Task for Windows:
  - **Generate proto:**
    - Generate API Proto Files: `Generate API Proto Files (win)`
    - Generate Proto Files (custom folder): `Generate Proto Files (win)`
  - **Dependency injection:**
    - Generate Wire: `Generate Wire`

- Makefile for Linux:
  - **Setup & Environment:**
    - Install golang, buf and related tools: `make install`
    - Check required tools: `make check-env`
    - Show all available targets: `make help`
  - **Generate proto:**
    - Generate API proto: `make api`
    - Generate config proto: `make config`  
  - **Dependency injection:**
    - Generate wire: `make generate`
  - **Complete workflows:**
    - Development (api + config + generate + dev-build): `make dev-all`
    - Production (api + config + generate + build): `make all`

#### Building for source
- VSCode Run Task for Windows:
  - Build: `Build (win)`
    - Select: Development, Production
- Makefile for Linux:
  - Build Development: `make dev-build`
  - Build Production: `make build`

## Docker
- VSCode Run Task for Windows:
  - Build Image: `Build Image (win)`
    - Select: Development, Production
  - Run Image: `Run Image (win)`
    - Select: Development, Production
- Makefile for Linux:
  - Build Development Image: `make dev-build-image`
  - Build Production Image: `make build-image`
  - Run Development Image: `make dev-run-image`
  - Run Production Image: `make run-image`

## Docker-Compose
- Makefile for Linux:
  - ELK Stack with Production: `make docker-compose`
  - ELK Stack with Development: `make dev-docker-compose`
---
## License

This program is open-sourced software licensed under the [MIT license](./LICENSE).