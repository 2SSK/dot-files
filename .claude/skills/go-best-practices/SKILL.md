---
name: go-best-practices
description: Go development best practices. Idiomatic Go, error handling, concurrency patterns, testing. Use when writing Go code.
compatibility: opencode
---

# Go Best Practices

Follow Go proverbs and community standards for all Go code.

## Core Principles

- **Simplicity**: Go is simple. Avoid over-engineering.
- **Idiomatic**: Follow effective Go guidelines
- **Performance**: Profile before optimizing
- **Testing**: Test-driven development

## Error Handling

```go
// Always wrap errors with context
if err != nil {
    return fmt.Errorf("failed to do operation: %w", err)
}

// Custom error types for known conditions
var NotFoundError struct{ Name string }
func (e NotFoundError) Error() string {
    return fmt.Sprintf("not found: %s", e.Name)
}
```

## Concurrency

```go
// Use channels for coordination, mutexes for state
// Worker pool pattern
jobs := make(chan Job, workerCount)
results := make(chan Result, workerCount)

// Start workers
for i := 0; i < workerCount; i++ {
    go worker(jobs, results)
}
```

## Context

```go
// All API calls must accept context
func DoSomething(ctx context.Context, arg Arg) (Result, error) {
    req, err := http.NewRequestWithContext(ctx, ...)
    // ...
}
```

## Testing

```go
// Table-driven tests
tests := []struct {
    name     string
    input    Arg
    expected Result
}{
    {"case 1", Arg{...}, Expected{...}},
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        result := DoSomething(tt.input)
        assert.Equal(t, tt.expected, result)
    })
}
```

## Build Commands

```bash
go fmt ./...
go vet ./...
golangci-lint run
go test -race -coverprofile=coverage.out ./...
go build -o binary ./cmd/...
```

## Quality Gates

- [ ] gofmt passes
- [ ] golangci-lint passes
- [ ] go test -race passes
- [ ] Coverage ≥ 80%
- [ ] No goroutine leaks