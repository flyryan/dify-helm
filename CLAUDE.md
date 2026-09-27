# CLAUDE.md

Guidance for Claude Code in this repo: a fork of [BorisPolonsky/dify-helm](https://github.com/BorisPolonsky/dify-helm) (chart `charts/dify`, version 0.29.0) plus the values that run ProductIQ's production Dify.

**This repository is public.** Never commit a secret, kubeconfig or token. Secrets live only in the gitignored `dify-prod-secrets.yaml`.

## Prod source of truth — where Dify changes are made

Every change to prod Dify is made here, in `dify-prod-values.yaml`, and applied with Helm. This covers the image, env vars, resources, probes, PVC sizes and Postgres config.

| | |
| --- | --- |
| Release / namespace | `dify` in `trendgpt-dify` (RDSec PSC-PROD; kubeconfig via `rone`, see TrendDifyFrontend `scripts/get-kubeconfig.sh` with `NAMESPACE=trendgpt-dify`) |
| Values | `dify-prod-values.yaml` (tracked, no secrets) + `dify-prod-secrets.yaml` (gitignored; template `dify-prod-secrets.example.yaml`) |
| Chart | `./charts/dify` (0.29.0, app 1.8.1) |
| Consumer | ProductIQ, repo TrendDifyFrontend (`../AATF/TrendDifyFrontend`) |

```bash
# Preview (renders against the cluster; does NOT run API validation)
helm upgrade dify ./charts/dify -n trendgpt-dify \
  -f dify-prod-values.yaml -f dify-prod-secrets.yaml --dry-run=server
# Apply — maintenance window only
helm upgrade dify ./charts/dify -n trendgpt-dify \
  -f dify-prod-values.yaml -f dify-prod-secrets.yaml
```

Rules:

- **No out-of-band edits.** Do not `kubectl set env`, `kubectl set image` or `kubectl patch` the Dify Deployments/StatefulSets unless the same change lands in `dify-prod-values.yaml` in the same session. A `helm upgrade` reverts anything the values don't carry. The one exception is a temporary app-id canary of `PIQ_DATASET_SOURCE_LABELS` for a retrieval eval: it is set live only, never written here, and restored to `on` when the eval ends (TrendDifyFrontend `dify-patches/README.md`, Patch 5). That is how the patched image, `PIQ_DATASET_SOURCE_LABELS`, the replica readiness probe and `wal_keep_size` drifted before 2026-09-27.
- **Reconcile before upgrading.** Render with the live values (`helm get values dify -n trendgpt-dify`) and compare against the live objects. Any live-only field must be added to the values first.
- **StatefulSet `volumeClaimTemplates` are immutable** (EKS 1.36 rejects the update). PVCs are expanded online with `kubectl patch pvc`. The values then carry the real size, and the next upgrade needs `kubectl -n trendgpt-dify delete sts <name> --cascade=orphan` first (pods and PVCs keep running; Helm recreates the StatefulSet). Preview before that delete, never after: diff `helm get manifest dify -n trendgpt-dify` against `helm template` of these values (both outputs hold secrets; write them outside the repo and delete them), and delete the StatefulSets only if the diff shows just the intended changes. As of 2026-09-27 this is pending for `dify-postgresql-primary` (template 64Gi, PVC 256Gi), `dify-postgresql-read` (32Gi / 256Gi) and `weaviate` (64Gi / 128Gi).
- **ProductIQ image patches** (`productiq-dify-api:1.8.1-piq.N`) are built in TrendDifyFrontend `dify-patches/`. Bump `image.api.tag` here when a new cut ships; the worker uses the same image.

## Secrets

- `dify-prod-secrets.yaml` holds the Weaviate API keys and user lists (Dify connects with the first allowed key). Rebuild it from `helm get values dify -n trendgpt-dify` if lost.
- Prod still runs several **chart-default (public) secrets**: the Postgres password, `api.secretKey`, `sandbox.auth.apiKey`, `pluginDaemon.auth.serverKey`/`difyApiKey`, and the first Weaviate key. `dify-prod-secrets.example.yaml` says what else must move when each is rotated.

## Other live objects outside the chart

- Ingress `dify-internal-ingress` (`dify-internal-ingress.yaml`, `deploy-internal-ingress.sh`)
- Service `dify-postgresql-read-external`
- `jfrog-docker-secret` on the namespace's default ServiceAccount, for the JFrog image pulls; refreshed monthly by TrendDifyFrontend `rotate-jfrog-token.yml`
- RBAC `k8s/dify/rbac-dify-db-endpoint-reader.yaml` in TrendDifyFrontend

## Other files

- `dify-custom-values.yaml`: legacy values for the old `trendgpt-difytest` environment (dify 1.4.3). Not prod.
- `charts/dify/values.yaml`: chart defaults (upstream); change only when porting upstream chart updates.
- `ci/`, `.github/`: upstream chart CI.

## Chart commands

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add weaviate https://weaviate.github.io/weaviate-helm
ct lint --config ct.yaml
```
