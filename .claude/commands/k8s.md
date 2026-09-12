---
description: Kubernetes deployment workflow
---
Run Kubernetes deployment workflow:
1. kubectl apply -f manifests/ --dry-run=client
2. kubectl apply -f manifests/ --dry-run=server
3. kubectl apply -f manifests/
4. kubectl rollout status deployment/app

For debugging: kubectl get pods, describe, logs.

Report results for each step.
