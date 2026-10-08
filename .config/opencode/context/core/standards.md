# Project Standards

## Code Standards

### All Languages
- **Formatting**: Language-specific formatters (gofmt, prettier, clang-format)
- **Linting**: Strict linting rules enabled
- **Types**: Strict typing, no implicit any
- **Errors**: Explicit error handling, no silently ignored errors

### Go
- Use `gofmt` for formatting
- Use `golangci-lint` for linting
- Strict `error` handling with wrapped errors
- Context propagation in all API calls
- Table-driven tests with subtests

### TypeScript/JavaScript
- Use ESLint + Prettier
- Strict TypeScript (`"strict": true`)
- No implicit `any`
- Minimum 90% test coverage

### C++
- Use clang-format for formatting
- Use clang-tidy + cppcheck for linting
- C++20/23 features where appropriate
- RAII everywhere, no raw new/delete

### React Native
- Cross-platform code first (80%+)
- Platform-specific code via `Platform.select()`
- Offline-first architecture

## Documentation Standards

### README Requirements
- Project overview
- Prerequisites
- Setup instructions
- Running locally
- Building for production
- Deployment instructions

### Code Documentation
- All public APIs documented
- Complex logic has inline comments
- README updated on significant changes

## Testing Standards

### Unit Tests
- Minimum 80% coverage
- Table-driven tests where applicable
- Fast execution (< 30s)

### Integration Tests
- For critical paths
- Real dependencies (not mocks)

### E2E Tests
- For user-facing features
- Use Playwright or similar

## CI/CD Standards

### Required Checks
- Lint
- Type check
- Tests
- Security scan
- Build verification

### Deployment
- Infrastructure as code
- GitOps workflow
- Automated rollbacks