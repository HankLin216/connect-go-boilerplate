# Project Todo List

## 1. Network Security & Proxy Configuration
- [x] **Hide Service Ports**: Ensure all backend services (Keycloak, Connect-Go App, etc.) are not exposed directly to the host. All external traffic must go through Envoy Proxy.
    - [x] Update `docker-compose.app.yml` to remove `ports` mapping for `connect-go-boilerplate` and `keycloak`.
    - [x] Update `docker-compose.monitor.yml` and `docker-compose.elk.yml` to remove exposed ports.
    - [x] Verify Envoy routing rules in `envoy/dynamic/listeners.yaml` and `clusters.yaml` and add routes for monitoring services.

## 2. Database Schema Management
- [ ] **PostgreSQL Schema Migration**: Implement a mechanism to manage database schema changes within the codebase.
    - [ ] Choose a migration tool (e.g., `golang-migrate`, `goose`, or `atlas`).
    - [ ] Create a `migrations/` directory for SQL scripts.
    - [ ] Add a makefile target or init code to run migrations on startup.

## 3. Role-Based Access Control (RBAC)
- [ ] **Implement RBAC Logic**: Integrate Keycloak roles into the application's authorization logic.
    - [ ] Extract roles from the JWT `realm_access.roles` or `resource_access.roles` claim in the Go interceptor.
    - [ ] Define permission policies (e.g., `editor` can write, `viewer` can only read).
    - [ ] Apply interceptors/middleware to gRPC/Connect handlers to enforce these policies.

## 4. Envoy Gateway Configuration
- [x] Integrate Keycloak with Helm
- [x] Configure SecurityPolicy for JWT validation
- [x] Fix Issuer Mismatch issues (use localhost:30080)
- [ ] Implement Envoy Gateway Rate Limiting (Global & Route-level)
- [ ] Configure Load Balancing Policies (Round Robin, Least Request, etc.)
- [ ] Add Circuit Breaking & Retry policies

## 5. Distributed Systems Features
- [ ] **Distributed Locking (Shared Lock)**: Implement a mechanism for coordinating tasks across multiple instances.
    - [ ] Choose a backend (Redis, PostgreSQL, or Etcd).
    - [ ] Implement a `DistLocker` interface for Acquire/Release.
    - [ ] Use cases: Leader election, Cron job coordination, preventing race conditions on critical resources.
- [ ] **Leader Election**: Implement leader election for high availability and single-writer scenarios.
    - [ ] Use Kubernetes native Leader Election (via `client-go/tools/leaderelection`) using Leases.
    - [ ] Ensure only the leader performs specific background tasks (e.g., cron jobs, consuming specific queues).
