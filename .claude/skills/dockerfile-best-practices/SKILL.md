---
name: dockerfile-best-practices
description: Docker and container best practices. Multi-stage builds, security, optimization. Use when creating Dockerfiles.
compatibility: opencode
---

# Docker Best Practices

Secure, optimized Dockerfiles for production containers.

## Core Principles

- **Small**: Minimal layers, minimal size
- **Secure**: Non-root user, read-only where possible
- **Fast**: Multi-stage builds, layer caching
- **Reproducible**: Deterministic builds

## Multi-Stage Builds

```dockerfile
# Build stage
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /binary ./cmd/app

# Runtime stage
FROM alpine:3.20
RUN adduser -D -u 1000 appuser
WORKDIR /app

COPY --from=builder /binary /app/app
USER appuser

ENTRYPOINT ["/app/app"]
```

## Security

```dockerfile
# Never run as root
USER appuser

# Read-only filesystem (where possible)
# HEALTHCHECK for monitoring
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget -q --spider http://localhost:8080/healthz || exit 1
```

## Optimization

```dockerfile
# Order: least frequently changed → most frequently changed
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build

# This way, go.mod changes trigger cache rebuild, not code changes
```

## Best Practices Checklist

- [ ] Minimal base image (alpine, distroless)
- [ ] Non-root user
- [ ] Multi-stage build
- [ ] No secrets in image
- [ ] Health check defined
- [ ] Labeled metadata
- [ ] Layer caching optimized

## Build Commands

```bash
# Build
docker build -t app:latest .

# Scan for vulnerabilities
hadolint Dockerfile
trivy image app:latest

# Build with buildkit
DOCKER_BUILDKIT=1 docker build -t app:latest .
```