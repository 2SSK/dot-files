# Development Standards

## Workflow Principles

### Core Values
- **Quality First**: Never compromise on code quality, testing, or observability
- **DevOps Mindset**: Infrastructure as code, automated pipelines, everything reproducible
- **Type Safety**: Full type coverage for TypeScript/Go, strict typing everywhere
- **Performance**: Profile first, optimize second. C++/systems code measured with benchmarks

### Language-Specific Standards

#### Go
```bash
go fmt ./...
golangci-lint run
go test -race -coverprofile=coverage.out ./...
go build -o binary ./cmd/...
```
- Strict `error` handling with wrapped errors using `fmt.Errorf`
- Context propagation in all API calls
- Table-driven tests with subtests
- Benchmark critical paths with `testing.B`
- Use `slog` for structured logging
- Configuration via environment variables with `viper` or `envconfig`
- Accept interfaces, return structs
- Channels for orchestration, mutexes for state
- Functional options for APIs
- Small, focused interfaces

```go
// Always wrap errors with context
if err != nil {
    return fmt.Errorf("failed to do operation: %w", err)
}

// Context in all API calls
func DoSomething(ctx context.Context, arg Arg) (Result, error) {
    req, err := http.NewRequestWithContext(ctx, ...)
    // ...
}
```

#### TypeScript/React
```bash
npm run lint
npm run type-check
npm run test
npm run build
```
- Strict TypeScript with `"strict": true`
- No `any` without explicit justification
- React functional components with hooks
- Proper error boundaries
- 90%+ test coverage on critical paths
- Use `tRPC` for type-safe API calls

#### React Native
```bash
npm run lint && npm run type-check && npx jest
cd ios && pod install && cd ..
npm run build:ios
```
- Cross-platform code > 80%
- Platform-specific code via `Platform.select()`
- Offline-first architecture with proper sync
- Performance: cold start < 1.5s, memory < 120MB
- Hermes engine, RAM bundles for production

#### C++
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined"
ctest --output-on-failure
```
- C++20/23 features where available
- Clang-Tidy and Cppcheck clean
- Zero compiler warnings with `-Wall -Wextra`
- AddressSanitizer and UBSan clean
- RAII everywhere, no raw new/delete
- Use `std::expected` for error handling
- Profile with `perf` and `pprof`

```cpp
// Smart pointers — always
auto ptr = std::make_unique<Resource>();
auto shared = std::make_shared<Cache>();

// Concepts (C++20)
template<typename T>
concept Hashable = requires(T a) {
    { std::hash<T>{}(a) } -> std::convertible_to<std::size_t>;
};

// std::expected (C++23)
std::expected<int, Error> divide(int a, int b) {
    if (b == 0) return std::unexpected{DivisionByZero{}};
    return a / b;
}
```

#### DevOps/SRE
- Infrastructure as Code (Terraform, Pulumi, or Ansible)
- Kubernetes manifests with Helm charts
- GitOps workflows (ArgoCD or Flux)
- SLO/SLI definitions for all services
- Alerting with proper severity levels
- Postmortems for all incidents

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
- [ ] Unit test coverage >= 80%
- [ ] Integration tests for critical paths
- [ ] E2E tests for user-facing features
- [ ] Performance benchmarks for critical code

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

## TDD Workflow

Enforce test-driven development for every implementation:

1. **Write Failing Test** — smallest unit of behavior, test fails because feature doesn't exist
2. **Write Minimal Code** — only what's needed to pass, no optimization yet
3. **Refactor** — clean up while tests pass, improve structure/names/organization

### Go Testing Pattern
```go
func TestUnitName(t *testing.T) {
    t.Run("should do thing", func(t *testing.T) {
        input := ...
        expected := ...
        result := DoThing(input)
        assert.Equal(t, expected, result)
    })
}
```

### TypeScript Testing Pattern
```typescript
describe('UnitName', () => {
  it('should do thing', () => {
    const result = doThing(input);
    expect(result).toEqual(expected);
  });
});
```

### C++ Testing Pattern
```cpp
TEST_F(UnitNameTest, ShouldDoThing) {
    auto input = ...;
    auto expected = ...;
    auto result = doThing(input);
    EXPECT_EQ(expected, result);
}
```

---

## Docker Best Practices

```dockerfile
# Multi-stage build
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /binary ./cmd/app

FROM alpine:3.20
RUN adduser -D -u 1000 appuser
WORKDIR /app
COPY --from=builder /binary /app/app
USER appuser
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q --spider http://localhost:8080/healthz || exit 1
ENTRYPOINT ["/app/app"]
```

- Minimal base image (alpine, distroless)
- Non-root user
- No secrets in image
- Layer caching optimized

---

## Observability

### Three Pillars
1. **Logging**: Structured logs with request ID, user ID
   - Go: `log/slog`
   - Node: `pino`
2. **Metrics**: Prometheus metrics (histograms, gauges, counters)
3. **Tracing**: OpenTelemetry distributed tracing

### SLI/SLO
- Latency: p99 < 100ms, SLO 99.9%
- Availability: success rate > 99.9%
- Quality: error rate < 0.1%

### Health Checks
```go
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    if !db.Healthy() {
        http.Error(w, "db unhealthy", http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
})
```

### Alerting
- Warning: SLO breach at 50% budget
- Critical: SLO breach at 80% budget
- Page: SLO breach at 95% budget

---

## Ship Workflow

When asked to "ship it", "commit and push", or "create a PR":

1. `git status` + `git diff` + `git log --oneline -5` + `git remote -v`
2. `git fetch origin && git rebase origin/main`
3. Stage relevant files (exclude .env, secrets, .DS_Store, *.db)
4. Commit with imperative mood (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`), first line <= 72 chars
5. `git push -u origin <branch>`
6. `gh pr create --title "..." --body "..." --base main`
7. Report commit hash, PR URL

**Never force-push to main. Never commit secrets. Always rebase first.**

---

## Agent Roles

Claude Code doesn't have native multi-agent. Adopt these roles by context:

- **golang-pro**: Idiomatic Go, concurrency, performance, cloud-native. gofmt clean, golangci-lint clean, race detector clean.
- **typescript-pro**: Strict TS, React hooks, tRPC, error boundaries. ESLint clean, 90%+ coverage.
- **cpp-pro**: Modern C++20/23, RAII, zero-overhead, sanitizers. clang-tidy clean, ASan/UBSan clean.
- **code-reviewer**: Quality, security, patterns, constructive feedback. Zero critical issues, cyclomatic complexity < 10.
- **security-engineer**: DevSecOps, vulnerability scanning, zero-trust. No secrets in code, input validated.
- **devops-engineer**: CI/CD, IaC, Kubernetes, GitOps. terraform validate, kubectl dry-run clean.
- **mobile-developer**: React Native, cross-platform > 80%, cold start < 1.5s.
- **sre-engineer**: SLO/SLI, reliability, chaos testing, toil reduction.
- **observability-reviewer**: Logging, metrics, tracing, alerting all configured.

---

## Quality Gates

### Go
- [ ] gofmt passes
- [ ] golangci-lint passes
- [ ] go test -race passes
- [ ] Coverage >= 80%

### TypeScript
- [ ] ESLint passes
- [ ] Type check passes
- [ ] Tests pass with >= 90% coverage
- [ ] Build succeeds

### C++
- [ ] clang-tidy passes
- [ ] Zero warnings
- [ ] ASan/UBSan clean
- [ ] Coverage >= 80%

### DevOps
- [ ] terraform validate
- [ ] kubectl dry-run passes
- [ ] hadolint clean
- [ ] trivy scan clean

---

## Agent & Skill Reference

54 specialized agents and 8 skill files are available in `~/.claude/agents/` and `~/.claude/skills/`. Use the Read tool to load them on-demand when context requires deep domain expertise.

### Agents (`~/.claude/agents/`)
| Directory | Agents |
|-----------|--------|
| architecture | api-designer, architect-reviewer, cloud-architect, graphql-architect |
| backend | backend-developer, cpp-pro, golang-pro, python-pro, rust-engineer, sql-pro |
| data | database-administrator, postgres-pro |
| devops | azure-infra-engineer, deployment-engineer, devops-engineer, devops-sre-mentor, kubernetes-specialist, terraform-engineer |
| frontend | frontend-developer, javascript-pro, nextjs-developer, react-specialist, typescript-pro |
| fullstack | fullstack-developer |
| incident-response | debugger, devops-incident-responder, error-detective, incident-responder, temporal-investigator |
| infrastructure | build-engineer, network-engineer, platform-engineer |
| mentor | mentor |
| mobile | game-developer, mobile-app-developer, mobile-developer |
| quality | code-reviewer, security-engineer |
| specialized | dependency-manager, payment-integration, product-strategist, refactoring-specialist, seo-specialist, sre-engineer |
| tools | cli-developer, context-manager, dx-optimizer, git-workflow-manager, multi-agent-coordinator, task-distributor, tooling-engineer |
| ux | commit, documentation-engineer, ui-designer, ux-researcher |

### Skills (`~/.claude/skills/`)
- `cpp-best-practices` — Modern C++20/23, RAII, zero-overhead abstractions
- `dockerfile-best-practices` — Multi-stage builds, security, optimization
- `go-best-practices` — Idiomatic Go, error handling, concurrency patterns
- `observability` — Logging, metrics, tracing, alerting
- `react-native-best-practices` — Cross-platform mobile, native modules
- `ship` — Commit, push, open PR workflow
- `tdd` — Test-Driven Development workflow
- `ui-ux-pro-max` — UI/UX design intelligence with searchable database
