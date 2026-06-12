# Day 11 — Model Answer

## How does Helm templating work?

Helm uses Go templates to generate Kubernetes YAML from chart templates + values:

1. Template files in `templates/` contain `{{ .Values.replicaCount }}` placeholders
2. `.Values` comes from `values.yaml` (defaults), `--set` flags, or `-f values-prod.yaml` overrides (merged, with `--set` taking highest priority)
3. At install/upgrade time, Helm renders the templates with the merged values into final YAML
4. The rendered YAML is applied to the cluster via `kubectl apply`

## `helm install` vs `helm upgrade` vs `helm rollback`

- **`helm install`** — deploys a chart for the first time, creates a new **release** (revision 1)
- **`helm upgrade`** — deploys a new version of an existing release, creating revision 2, 3, etc.
- **`helm rollback`** — reverts to a previous revision (e.g., `helm rollback myapp 1` goes back to revision 1)

Each upgrade creates a new revision, stored as Secrets in the cluster, allowing unlimited rollbacks.

## How to manage different environments with the same chart:

Use separate values files per environment:
```bash
helm install myapp ./myapp -f values.yaml -f values-staging.yaml
helm install myapp ./myapp -f values.yaml -f values-prod.yaml
```

Or use `--set` for CI/CD overrides. The chart stays the same — only the values change. This guarantees that the same chart version behaves consistently across environments with different configuration.
