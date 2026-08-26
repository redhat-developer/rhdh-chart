# Lightspeed & OKP Integration

This document covers the Lightspeed (Intelligent Assistant) and OKP (Offline Knowledge Portal)
integration in the RHDH Helm chart.

## Architecture

The Lightspeed integration deploys two components alongside the RHDH (Backstage) pod:

1. **Lightspeed Core (LCORE) sidecar** — runs inside the RHDH pod as a sidecar container,
   providing the inference API (`/v1/models`, `/v1/chat/completions`, etc.).
2. **OKP deployment** *(optional)* — a standalone `Deployment` with its own `Service`,
   `Route` (OpenShift), or `Ingress` (vanilla K8s). Hosts Solr + httpd for document retrieval.

OKP is **not** part of the RHDH Deployment — it is a separate workload that LCORE talks to via `OKP_SERVICE_URL`.

## Deployment Scenarios

| Scenario | OKP deployed? | Config used | RAG sources? |
|---|---|---|---|
| **OpenShift (auto)** | Yes — automatic when `lightspeed.enabled=true` | `lightspeed-stack.yaml` (with `rag:` + `okp:`) | Yes |
| **Vanilla K8s (default)** | No — unless `okp.ingress.host` is set | `lightspeed-stack-no-okp.yaml` | No |
| **Vanilla K8s (opt-in)** | Yes — when `okp.ingress.host` is provided | `lightspeed-stack.yaml` (with `rag:` + `okp:`) | Yes |

## Helm Install Flags

### OpenShift (OKP auto-enabled)

```bash
helm install rhdh ./charts/rhdh \
  --set lightspeed.enabled=true \
  --set lightspeed.existingSecret=lightspeed-secret \
  --set openshift.clusterRouterBase=$(oc get ingresses.config/cluster -o jsonpath='{.spec.domain}')
```

### Vanilla Kubernetes — No OKP (default)

```bash
helm install rhdh ./charts/rhdh \
  --namespace rhdh \
  --set lightspeed.enabled=true \
  --set lightspeed.existingSecret=lightspeed-secret \
  --set openshift.route.enabled=false \
  --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=rhdh.mydomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
  --set ingress.className=nginx
```

### Vanilla Kubernetes — OKP Opt-in

```bash
helm install rhdh ./charts/rhdh \
  --namespace rhdh \
  --set lightspeed.enabled=true \
  --set lightspeed.existingSecret=lightspeed-secret \
  --set openshift.route.enabled=false \
  --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=rhdh.mydomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
  --set ingress.className=nginx \
  --set lightspeed.okp.ingress.host=okp.mydomain.com \
  --set lightspeed.okp.ingress.className=nginx \
  --set lightspeed.okp.imagePullSecrets[0]=rh-registry-secret
```

> **Tip — local testing with Kind:** If you don't have a real domain, use
> [nip.io](https://nip.io) for automatic DNS resolution to localhost. For example,
> `rhdh.127.0.0.1.nip.io` and `okp.127.0.0.1.nip.io` resolve to `127.0.0.1`
> without `/etc/hosts` changes. Install an ingress controller first
> (e.g. `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml`).

## Vanilla Kubernetes Prerequisites

On vanilla Kubernetes (unlike OpenShift), the chart requires additional setup:

1. **Disable the OpenShift Route** — set `openshift.route.enabled=false` (the chart
   creates a Route by default, which requires the OpenShift Route CRD).
2. **Enable Ingress** — set `ingress.enabled=true` with a hostname and ingress class.
   An ingress controller (e.g. [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
   must be installed in the cluster.
3. **OKP image pull secret** — the OKP image is hosted on `registry.redhat.io`, which
   requires authentication. Create a pull secret from your Red Hat registry credentials
   or Podman auth:

```bash
# From Podman auth (reuses existing login)
kubectl create secret generic rh-registry-secret \
  --from-file=.dockerconfigjson=$HOME/.config/containers/auth.json \
  --type=kubernetes.io/dockerconfigjson \
  --namespace <namespace>

# Or from Docker auth
kubectl create secret generic rh-registry-secret \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --namespace <namespace>
```

Then pass the secret name via `--set lightspeed.okp.imagePullSecrets[0]=rh-registry-secret`.
No volume mounting is needed — Kubernetes uses `imagePullSecrets` on the Pod spec to
authenticate with the registry during image pull.

> **Note:** On OpenShift, image pull secrets are typically configured cluster-wide or via
> the `openshift-config` pull-secret, so `imagePullSecrets` is usually not needed.

## Creating the Lightspeed Secret

The chart does **not** auto-create a Kubernetes Secret for inference provider credentials.
You must create it yourself and reference it via `lightspeed.existingSecret`.

Use `charts/rhdh/files/lightspeed/secret.example.yaml` as a template:

```bash
kubectl create secret generic lightspeed-secret \
  --namespace <namespace> \
  --from-literal=OPENAI_API_KEY=<your-key> \
  --from-literal=OTEL_SDK_DISABLED=true
```

Key environment variables in the secret:

| Variable | Purpose | Required? |
|---|---|---|
| `OPENAI_API_KEY` | OpenAI inference key | If using OpenAI provider |
| `VLLM_URL`, `VLLM_API_KEY` | vLLM inference endpoint | If using vLLM provider |
| `VERTEX_AI_PROJECT`, `VERTEX_AI_LOCATION` | Google Vertex AI | If using Vertex AI |
| `OLLAMA_URL` | Ollama endpoint | If using Ollama |
| `OTEL_SDK_DISABLED` | Set `"true"` to disable OTEL SDK (prevents LCORE crash) | Recommended |
| `ENABLE_VALIDATION`, `VALIDATION_PROVIDER`, `VALIDATION_MODEL_NAME` | Input validation | Optional |

## OKP Configuration

OKP values are under `lightspeed.okp.*`:

| Value | Default | Description |
|---|---|---|
| `okp.image.registry` | `registry.redhat.io` | OKP container image registry |
| `okp.image.repository` | `offline-knowledge-portal/rhokp-rhel9` | OKP image repository |
| `okp.image.tag` | `1.2.10-1786628394` | Pinned OKP image tag |
| `okp.replicaCount` | `1` | Number of OKP replicas |
| `okp.solr.memory` | `1g` | Solr JVM heap size |
| `okp.resources.requests.memory` | `2Gi` | Memory request |
| `okp.resources.limits.memory` | `4Gi` | Memory limit |
| `okp.imagePullSecrets` | `[]` | Image pull secrets (needed for vanilla K8s) |
| `okp.route.enabled` | `true` | Create OpenShift Route |
| `okp.ingress.enabled` | `true` | Create K8s Ingress (requires `host`) |
| `okp.ingress.host` | `""` | Ingress hostname (triggers OKP opt-in on K8s) |
| `okp.ingress.className` | `""` | Ingress class (e.g. `nginx`) |
| `okp.chunkFilterQuery` | `product:*developer_hub*` | Solr filter for RHDH docs |

## Lightspeed Config Sync

Vendored config files in `charts/rhdh/files/lightspeed/` are synced from the upstream
[lightspeed-configs](https://github.com/redhat-ai-dev/lightspeed-configs) repository:

```bash
hack/sync-lightspeed-configs.sh            # sync from main
hack/sync-lightspeed-configs.sh --check    # check if files match upstream
hack/sync-lightspeed-configs.sh --ref v1.0 # sync from a specific ref
```

The sync produces two stack config variants:
- `lightspeed-stack.yaml` — full config with `rag:` and `okp:` sections
- `lightspeed-stack-no-okp.yaml` — same file with `rag:`/`okp:` stripped via `yq`

The chart's ConfigMap template automatically selects the correct variant based on whether OKP is active.
