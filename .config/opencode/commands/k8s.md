---
name: k8s
description: Kubernetes deployment workflow. Apply manifests, check status, view logs. Use for K8s deployments.
agent: kubernetes-specialist
---

# Kubernetes Development Command

Run K8s deployment workflow.

## When to Use

- Deploy to Kubernetes
- Check deployment status
- View pod logs
- Debug issues

## Workflow Options

### Dry Run (Validate)
```bash
kubectl apply -f manifests/ --dry-run=client
kubectl apply -f manifests/ --dry-run=server
```

### Deploy
```bash
kubectl apply -f manifests/
kubectl rollout status deployment/app
```

### Debug
```bash
kubectl get pods -n app-ns
kubectl describe pod/app-xxx -n app-ns
kubectl logs -f pod/app-xxx -n app-ns
kubectl exec -it pod/app-xxx -n app-ns -- sh
```

### Rollback
```bash
kubectl rollout undo deployment/app -n app-ns
```

## Quality Gates

- [ ] --dry-run=client passes
- [ ] --dry-run=server passes
- [ ] All pods ready
- [ ] No CrashLoopBackOff