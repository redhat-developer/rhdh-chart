# Intelligent Assistant & OKP Integration

This document covers the Intelligent Assistant (formerly Lightspeed) and OKP (Offline Knowledge Portal)
integration in the RHDH Helm chart.

## Architecture

The Intelligent Assistant integration deploys two components alongside the RHDH (Backstage) pod:

1. **Lightspeed Core (LCORE) sidecar** — runs inside the RHDH pod as a sidecar container,
   providing the inference API (`/v1/models`, `/v1/chat/completions`, etc.).
2. **OKP deployment** *(optional)* — a standalone `Deployment` with its own `Service`,
   `Route` (OpenShift), or `Ingress` (vanilla K8s). Hosts Solr + httpd for document retrieval.

OKP is **not** part of the RHDH Deployment — it is a separate workload that LCORE talks to via `OKP_SERVICE_URL`.

## Deployment Scenarios

| Scenario | OKP deployed? | Config used | RAG sources? |
|---|---|---|---|
| **OpenShift (auto)** | Yes — automatic when `intelligentAssistant.enabled=true` | `lightspeed-stack.yaml` (with `rag:` + `okp:`) | Yes |
| **Vanilla K8s (default)** | No — unless `okp.ingress.host` is set | `lightspeed-stack-no-okp.yaml` | No |
| **Vanilla K8s (opt-in)** | Yes — when `okp.ingress.host` is provided | `lightspeed-stack.yaml` (with `rag:` + `okp:`) | Yes |

## Helm Install Flags

### OpenShift (OKP auto-enabled)

```bash
helm install rhdh ./charts/rhdh \
  --set intelligentAssistant.enabled=true \
  --set intelligentAssistant.existingSecret=lightspeed-secret \
  --set openshift.clusterRouterBase=$(oc get ingresses.config/cluster -o jsonpath='{.spec.domain}')
```

### Vanilla Kubernetes — No OKP (default)

```bash
helm install rhdh ./charts/rhdh \
  --namespace rhdh \
  --set intelligentAssistant.enabled=true \
  --set intelligentAssistant.existingSecret=lightspeed-secret \
  --set openshift.route.enabled=false \
  --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=rhdh.mydomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
  --set ingress.className=nginx
```

### Vanilla Kubernetes — OKP Opt-in (HTTP)

```bash
helm install rhdh ./charts/rhdh \
  --namespace rhdh \
  --set intelligentAssistant.enabled=true \
  --set intelligentAssistant.existingSecret=lightspeed-secret \
  --set openshift.route.enabled=false \
  --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=rhdh.mydomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
  --set ingress.className=nginx \
  --set intelligentAssistant.okp.ingress.host=okp.mydomain.com \
  --set intelligentAssistant.okp.ingress.className=nginx \
  --set intelligentAssistant.okp.imagePullSecrets[0]=rh-registry-secret \
  --set intelligentAssistant.okp.securityContext.runAsUser=1001
```

### Vanilla Kubernetes — OKP Opt-in (HTTPS)

```bash
helm install rhdh ./charts/rhdh \
  --namespace rhdh \
  --set intelligentAssistant.enabled=true \
  --set intelligentAssistant.existingSecret=lightspeed-secret \
  --set openshift.route.enabled=false \
  --set ingress.enabled=true \
  --set 'ingress.hosts[0].host=rhdh.mydomain.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix' \
  --set ingress.className=nginx \
  --set intelligentAssistant.okp.ingress.host=okp.mydomain.com \
  --set intelligentAssistant.okp.ingress.className=nginx \
  --set intelligentAssistant.okp.ingress.tls.enabled=true \
  --set intelligentAssistant.okp.ingress.tls.secretName=okp-tls \
  --set intelligentAssistant.okp.imagePullSecrets[0]=rh-registry-secret \
  --set intelligentAssistant.okp.securityContext.runAsUser=1001
```

> **Note — `runAsUser` on vanilla K8s:** The OKP image uses a non-numeric user
> (`default`, UID 1001). Kubernetes cannot verify `runAsNonRoot` with a non-numeric
> user, causing `CreateContainerConfigError`. On OpenShift this is handled
> automatically by the SCC. On vanilla K8s, add
> `--set intelligentAssistant.okp.securityContext.runAsUser=1001` to resolve it.

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

Then pass the secret name via `--set intelligentAssistant.okp.imagePullSecrets[0]=rh-registry-secret`.
No volume mounting is needed — Kubernetes uses `imagePullSecrets` on the Pod spec to
authenticate with the registry during image pull.

> **Note:** On OpenShift, image pull secrets are typically configured cluster-wide or via
> the `openshift-config` pull-secret, so `imagePullSecrets` is usually not needed.

## Creating the Intelligent Assistant Secret

The chart does **not** auto-create a Kubernetes Secret for inference provider credentials.
You must create it yourself and reference it via `intelligentAssistant.existingSecret`.

Use `charts/rhdh/files/intelligent-assistant/secret.example.yaml` as a template:

```bash
kubectl create secret generic lightspeed-secret \
  --namespace <namespace> \
  --from-literal=OPENAI_API_KEY=<your-key>
```

Key environment variables in the secret:

| Variable | Purpose | Required? |
|---|---|---|
| `OPENAI_API_KEY` | OpenAI inference key | If using OpenAI provider |
| `VLLM_URL`, `VLLM_API_KEY` | vLLM inference endpoint | If using vLLM provider |
| `VERTEX_AI_PROJECT`, `VERTEX_AI_LOCATION` | Google Vertex AI | If using Vertex AI |
| `OLLAMA_URL` | Ollama endpoint | If using Ollama |
| `ENABLE_VALIDATION`, `VALIDATION_PROVIDER`, `VALIDATION_MODEL_NAME` | Input validation | Optional |

## HTTPS and TLS

### OpenShift

On OpenShift, OKP is exposed via a TLS-terminated Route. The chart sets
`OKP_SERVICE_URL` to `https://` and `insecureEdgeTerminationPolicy: Redirect`.

Most OpenShift clusters use **self-signed router certificates** by default. LCORE's
Python SSL stack (`httpx` for Solr, `requests` for other calls) does not trust these
out of the box. The chart handles this automatically when OKP is active:

1. Combines the system CA bundle (`/etc/pki/tls/certs/ca-bundle.crt`) with the
   cluster's service account CA (`/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`)
   into `/tmp/combined-ca-bundle.crt`.
2. Sets `SSL_CERT_FILE` and `REQUESTS_CA_BUNDLE` to point to the combined bundle.

This is done via a command override on the LCORE container — the chart replaces the
default entrypoint with a shell script that prepares the CA bundle before calling the
original entrypoint. If `commandOverride` or `argsOverride` is set on the LCORE core
container, the CA bundle logic is skipped (the user is responsible for their own setup).

### Vanilla Kubernetes

On vanilla K8s, `OKP_SERVICE_URL` is `http://` by default (no TLS on the Ingress).
To enable HTTPS, provide a TLS secret and enable TLS on the OKP Ingress:

```bash
# Create a TLS secret (from cert-manager, or manually with openssl)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/okp-tls.key -out /tmp/okp-tls.crt \
  -subj "/CN=okp.mydomain.com" \
  -addext "subjectAltName=DNS:okp.mydomain.com"

kubectl create secret tls okp-tls -n <namespace> \
  --cert=/tmp/okp-tls.crt --key=/tmp/okp-tls.key

# Then set TLS on the OKP Ingress
helm install rhdh ./charts/rhdh \
  ... \
  --set intelligentAssistant.okp.ingress.host=okp.mydomain.com \
  --set intelligentAssistant.okp.ingress.tls.enabled=true \
  --set intelligentAssistant.okp.ingress.tls.secretName=okp-tls
```

When `okp.ingress.tls.enabled=true`, the chart sets `OKP_SERVICE_URL` to `https://`.
The nginx ingress controller terminates TLS at the Ingress — traffic from Ingress to
OKP is still HTTP on port 8080 (same as OpenShift edge termination). In production,
use [cert-manager](https://cert-manager.io/) for automatic certificate management.

The LCORE command override (CA bundle script) runs whenever OKP is active, regardless
of platform. On K8s the `if` guard checks for the service account CA file — if it
exists, the combined bundle is created; otherwise LCORE falls back to default system CAs.

When OKP is **not** active, LCORE uses default arguments with no command override.

## OKP Configuration

OKP values are under `intelligentAssistant.okp.*`:

| Value | Default | Description |
|---|---|---|
| `okp.image.registry` | `registry.redhat.io` | OKP container image registry |
| `okp.image.repository` | `offline-knowledge-portal/rhokp-rhel9` | OKP image repository |
| `okp.image.tag` | `1.2.12-1788274041` | Pinned OKP image tag |
| `okp.replicaCount` | `1` | Number of OKP replicas |
| `okp.solr.memory` | `1g` | Solr JVM heap size |
| `okp.resources.requests.memory` | `2Gi` | Memory request |
| `okp.resources.limits.memory` | `4Gi` | Memory limit |
| `okp.securityContext` | restricted | Security context for the OKP container |
| `okp.imagePullSecrets` | `[]` | Image pull secrets (merged with `global.imagePullSecrets`) |
| `okp.route.enabled` | `true` | Create OpenShift Route |
| `okp.ingress.enabled` | `true` | Create K8s Ingress (requires `host`) |
| `okp.ingress.host` | `""` | Ingress hostname (triggers OKP opt-in on K8s) |
| `okp.ingress.className` | `""` | Ingress class (e.g. `nginx`) |
| `okp.ingress.tls.enabled` | `false` | Enable TLS on the OKP Ingress |
| `okp.ingress.tls.secretName` | `""` | TLS secret name (cert+key) |
| `okp.ingress.annotations` | `{}` | Annotations on the OKP Ingress |
| `okp.affinity` | `{}` | Affinity rules for OKP pod assignment |
| `okp.nodeSelector` | `{}` | Node labels for OKP pod assignment |
| `okp.tolerations` | `[]` | Tolerations for OKP pod scheduling |
| `okp.topologySpreadConstraints` | `[]` | Topology spread constraints for OKP pods |
| `okp.readinessProbe.initialDelaySeconds` | `10` | Readiness probe initial delay |
| `okp.readinessProbe.periodSeconds` | `10` | Readiness probe period |
| `okp.livenessProbe.initialDelaySeconds` | `30` | Liveness probe initial delay |
| `okp.livenessProbe.periodSeconds` | `30` | Liveness probe period |

## Lightspeed Config Sync

Vendored config files in `charts/rhdh/files/intelligent-assistant/` are synced from the upstream
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
