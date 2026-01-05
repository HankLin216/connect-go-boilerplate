# Project Todo List

## 1. Network Security & Proxy Configuration
- [ ] **Hide Service Ports**: Ensure all backend services (Keycloak, Connect-Go App, etc.) are not exposed directly to the host. All external traffic must go through Envoy Proxy.
    - [ ] Update `docker-compose.app.yml` to remove `ports` mapping for `connect-go-boilerplate` and `keycloak`.
    - [ ] Verify Envoy routing rules in `envoy/dynamic/listeners.yaml` and `clusters.yaml`.

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
