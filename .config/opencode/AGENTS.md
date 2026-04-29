# Development Standards

## Workflow Principles

### Core Values
- **Quality First**: Never compromise on code quality, testing, or observability
- **DevOps Mindset**: Infrastructure as code, automated pipelines, everything reproducible
- **Type Safety**: Full type coverage for TypeScript/Go, strict typing everywhere
- **Performance**: Profile first, optimize second. C++/systems code measured with benchmarks

### Language-Specific Standards

#### Go (golang-pro)
```bash
# Always run before committing
go fmt ./...
golangci-lint run
go test -race -coverprofile=coverage.out ./...
go build -o binary ./cmd/...
```

**Standards:**
- Strict `error` handling with wrapped errors using `fmt.Errorf`
- Context propagation in all API calls
- Table-driven tests with subtests
- Benchmark critical paths with `testing.B`
- Use `slog` for structured logging
- Configuration via environment variables with `viper` or `envconfig`

#### TypeScript/React (typescript-pro)
```bash
# Always run before committing
npm run lint
npm run type-check
npm run test
npm run build
```

**Standards:**
- Strict TypeScript with `"strict": true`
- No `any` without explicit justification
- React functional components with hooks
- Proper error boundaries
- 90%+ test coverage on critical paths
- Use `tRPC` for type-safe API calls

#### React Native (mobile-developer)
```bash
# Pre-commit checks
npm run lint
npm run type-check
npx jest
cd ios && pod install && cd ..
npm run build:ios
```

**Standards:**
- Cross-platform code > 80%
- Platform-specific code via `Platform.select()`
- Offline-first architecture with proper sync
- Push notifications for iOS (APNS) and Android (FCM)
- Performance: cold start < 1.5s, memory < 120MB
- Use `@react-native-async-storage/async-storage` for secure local storage
- Hermes engine, RAM bundles for production

#### C++ (cpp-pro)
```bash
# Pre-commit checks
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
# Run sanitizers
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined"
ctest --output-on-failure
```

**Standards:**
- C++20/23 features where available
- Clang-Tidy and Cppcheck clean
- Zero compiler warnings with `-Wall -Wextra`
- AddressSanitizer and UBSan clean
- RAII everywhere, no raw new/delete
- Use `std::expected` for error handling
- Lock-free data structures for concurrency
- Profile with `perf` and `pprof`

#### DevOps/SRE
```bash
# Infrastructure validation
terraform validate
kubectl --dry-run=client
docker build --check
```

**Standards:**
- Infrastructure as Code (Terraform, Pulumi, or Ansible)
- Kubernetes manifests with Helm charts
- GitOps workflows (ArgoCD or Flux)
- SLO/SLI definitions for all services
- Alerting with proper severity levels
- Postmortems for all incidents
- Runbooks for all operational procedures

---

## Definition of Done

A task is complete when:

### Code Quality
- [ ] All tests pass (unit, integration, E2E)
- [ ] Linting passes without warnings
- [ ] Type checking passes
- [ ] No security vulnerabilities introduced
- [ ] Code review approved

### Testing
- [ ] Unit test coverage ≥ 80%
- [ ] Integration tests for critical paths
- [ ] E2E tests for user-facing features
- [ ] Performance benchmarks for critical code
- [ ] Load testing for high-traffic endpoints

### Observability
- [ ] Structured logging implemented
- [ ] Metrics exposed (Prometheus format)
- [ ] Distributed tracing configured
- [ ] Health check endpoints
- [ ] Alerting rules defined

### Documentation
- [ ] API documentation (OpenAPI/Swagger)
- [ ] README updated
- [ ] Inline code comments for complex logic
- [ ] Deployment/runbook documentation

---

## Agent Orchestration

### Standard Development Workflow

```
User request
  → architect (plan - if non-trivial feature)
  → build (review plan, scope work)
  → golang-pro / typescript-pro / cpp-pro (implement - TDD)
  → code-reviewer (verify quality)
  → security-reviewer (verify security)
  → observability-reviewer (verify observability)
  → devops-engineer (CI/CD, deployment - if infra changes)
  → build (verify all quality gates)
  → qa (E2E tests)
  → developer-advocate (update docs)
  → build (report completion)
```

### Context Switching
- Use Tab to switch between primary agents based on current task
- `@golang-pro` for Go backend work
- `@typescript-pro` for TypeScript/React frontend
- `@mobile-developer` for React Native
- `@cpp-pro` for C++/systems code
- `@devops-engineer` for infrastructure/DevOps

---

## Quality Gates

### Go Projects
```yaml
gates:
  - command: go fmt ./... && go vet ./...
  - command: golangci-lint run
  - command: go test -race ./...
  - coverage: 80
  - command: go build ./...
```

### TypeScript Projects
```yaml
gates:
  - command: npm run lint
  - command: npm run type-check
  - command: npm test -- --coverage
  - coverage: 90
  - command: npm run build
```

### C++ Projects
```yaml
gates:
  - command: cmake --build build -- -j4
  - command: ctest --output-on-failure
  - coverage: 80
  - command: clang-tidy build/*.cpp
  - command: valgrind --leak-check=summary ./test
```

### DevOps
```yaml
gates:
  - command: terraform validate
  - command: kubectl apply --dry-run=client
  - command: hadolint Dockerfile
  - command: trivy image scan
```

---

## Productivity Tips

1. **Plan First**: Use Plan mode for complex features before implementing
2. **Context is King**: Provide clear context in prompts for better results
3. **Agent Switching**: Tab through agents based on current task domain
4. **MCP Tools**: Leverage MCP servers for database queries, browser automation
5. **Custom Commands**: Use `/` commands for repetitive workflows
6. **Subagents**: Delegate specialized tasks to focused subagents

---

## Multi-Agent Collaboration

### Primary Agents (Tab-switchable)
- **build** - Orchestrator and task coordinator
- **golang-pro** - Go backend development
- **typescript-pro** - TypeScript/React frontend
- **cpp-pro** - C++/systems programming
- **devops-engineer** - Infrastructure and deployment

### Subagents (invoked with @)
- **code-reviewer** - Code quality review
- **security-reviewer** - Security audit
- **observability-reviewer** - Observability check
- **devops-sre-mentor** - Learning and guidance
- **sre-engineer** - SLO/SLI implementation
- **kubernetes-specialist** - K8s deployment