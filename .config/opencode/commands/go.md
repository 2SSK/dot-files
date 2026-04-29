---
name: go
description: Go development workflow. Run tests, lint, build, benchmark. Use for any Go project work.
agent: golang-pro
---

# Go Development Command

Run the appropriate Go workflow based on context.

## When to Use

- Implement new Go feature
- Run Go tests
- Build Go binary
- Profile Go application

## Workflow Options

### Test & Verify
```bash
go fmt ./...
go vet ./...
golangci-lint run
go test -race -v ./...
```

### Build
```bash
go build -o bin/app ./cmd/...
```

### Benchmark
```bash
go test -bench=. -benchmem ./...
```

### Profile
```bash
go test -cpuprofile=cpu.prof ./...
go tool pprof cpu.prof
```

## Quality Gates

Before committing Go code:
- [ ] go fmt passes
- [ ] golangci-lint passes
- [ ] go test -race passes
- [ ] Tests pass