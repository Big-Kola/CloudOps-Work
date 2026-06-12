# Day 9 — Model Answer

## What's the difference between ConfigMap and Secret?

- **ConfigMap** stores non-sensitive configuration (plaintext). Environment names, log levels, config files.
- **Secret** stores sensitive data (base64-encoded by default). Passwords, API tokens, SSH keys, TLS certs.
- Secrets can be encrypted at rest if etcd encryption is enabled (recommended in production).
- Secrets support additional types: `Opaque` (generic), `kubernetes.io/tls` (TLS certs), `kubernetes.io/dockerconfigjson` (registry creds).

## How would you handle database passwords across dev/staging/prod?

1. Store the actual password in an external secrets manager: Vault, AWS Secrets Manager, or GCP Secret Manager
2. Use an external-secrets operator or CSI driver to sync secrets into the cluster
3. Keep the ConfigMap/Secret YAML in Git **without** the real values (skeleton YAML or use Helm with env-specific values files)
4. Each namespace (dev/staging/prod) gets its own Secret injected by the operator
5. Never commit raw passwords to Git — ever

## Does updating a ConfigMap update running pods automatically?

**Not by default.** If the ConfigMap is mounted as a volume, the files are updated automatically within minutes (symlink swap). If injected as environment variables, pods MUST be restarted (e.g., `kubectl rollout restart deploy/app`) to pick up changes. Controllers like Reloader can automate this by watching ConfigMap/Secret changes.
