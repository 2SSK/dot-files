---
name: observability
description: Observability best practices. Logging, metrics, tracing, alerting. Essential for production services. Use for any backend service.
compatibility: opencode
---

# Observability Best Practices

Structured logging, metrics, distributed tracing, and alerting for production systems.

## The Three Pillars

### 1. Logging

```go
// Go: slog for structured logging
import "log/slog"

slog.Info("request completed",
    "method", r.Method,
    "path", r.URL.Path,
    "duration_ms", duration.Milliseconds(),
    "status", statusCode,
)

// Node.js: pino
import pino from 'pino';

const logger = pino({
  level: 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
});
```

### 2. Metrics

```go
// Prometheus metrics
import "github.com/prometheus/client_golang/prometheus"

var requestDuration = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{
        Name:    "http_request_duration_seconds",
        Help:    "HTTP request duration in seconds",
        Buckets:  []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5},
    },
    []string{"method", "path", "status"},
)

var activeRequests = prometheus.NewGauge(prometheus.GaugeOpts{
    Name: "active_requests",
    Help: "Number of active requests",
})
```

### 3. Tracing

```go
// OpenTelemetry
import "go.opentelemetry.io/otel"
import "go.opentelemetry.io/otel/trace"

func Handler(ctx context.Context, w http.ResponseWriter, r *http.Request) {
    ctx, span := otel.Tracer("http").Start(ctx, r.URL.Path)
    defer span.End()
    
    // business logic
    span.SetAttributes(
        attribute.String("http.method", r.Method),
        attribute.Int("http.status_code", statusCode),
    )
}
```

## SLI/SLO Definitions

### Latency
- **SLI**: p99 latency < 100ms
- **SLO**: 99.9% of requests

### Availability
- **SLI**: Request success rate > 99.9%
- **SLO**: < 0.1% error budget consumed per month

### Quality
- **SLI**: Successful responses with no errors
- **SLO**: Error rate < 0.1%

## Health Checks

```go
// Liveness: process is running
// Readiness: service can handle requests
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    // check dependencies
    if !db.Healthy() {
        http.Error(w, "db unhealthy", http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
})
```

## Alerting

- **Warning**: SLO breach at 50% budget
- **Critical**: SLO breach at 80% budget
- **Page**: SLO breach at 95% budget

## Quality Gates

- [ ] Structured logs with request ID, user ID
- [ ] Prometheus metrics exported
- [ ] Distributed tracing configured
- [ ] Health check endpoints
- [ ] Alerting rules defined
- [ ] SLO dashboard