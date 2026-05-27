https://redhat.atlassian.net/browse/RHDHBUGS-2577 

# RHDHBUGS-2577: Orchestrator DB Creation Job Fix

## Background

When the Orchestrator is enabled, the Helm chart creates a Kubernetes Job called
`create-sonataflow-database`. This Job runs a `psql` command to create the
`sonataflow` database in PostgreSQL. The Job has a `backoffLimit` that tells
Kubernetes how many times to retry if it fails.

There were three problems with this Job. This document explains all of them.

---

## Problem 1: The Job silently swallows errors

### What was happening

The old command looked like this:

```sh
psql -h <host> -p 5432 -U postgres -c 'CREATE DATABASE sonataflow;' || echo WARNING: Could not create database
```

The `|| echo WARNING...` at the end is the problem. In shell, `||` means
"if the previous command fails, run this instead." The `echo` command always
succeeds (exit code 0), so the overall command always exits 0 — even when `psql`
fails.

Kubernetes checks the exit code to decide if the Job succeeded or failed:

- Exit code 0 = success
- Any other exit code = failure (retry up to `backoffLimit` times)

Because the exit code was always 0, Kubernetes always thought the Job succeeded.
The `backoffLimit` was set to 2, but it never triggered because the Job never
"failed" from Kubernetes' perspective.

### Real-world impact

If `psql` couldn't connect (wrong password, network issue, PostgreSQL not ready),
the Job would log `WARNING: Could not create database` and report success.
The `sonataflow` database would not exist, and downstream services (Data Index,
Job Service) would fail later with confusing errors that were hard to trace back
to a missing database.

### What we changed: the conditional error handling logic

The new command:

```sh
psql -h <host> -p 5432 -U postgres -c 'CREATE DATABASE sonataflow;' 2>&1 || {
  if psql -h <host> -p 5432 -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='sonataflow'" | grep -q 1; then
    echo "Database 'sonataflow' already exists, skipping creation."
  else
    echo "ERROR: Failed to create database 'sonataflow'."
    exit 1
  fi
}
```

Here is exactly what this does, step by step:

1. **Try to create the database.** `psql ... -c 'CREATE DATABASE sonataflow;'`
   runs the SQL command. The `2>&1` redirects stderr into stdout so we capture
   all output.

2. **If it succeeds (exit code 0):** The `||` block is skipped entirely. The Job
   exits 0. Kubernetes marks it as successful. Done.

3. **If it fails (any non-zero exit code):** The `|| { ... }` block runs. But
   "failed" could mean two very different things:
   - The database already exists (PostgreSQL returns an error for `CREATE DATABASE`
     when the database is already there). This is fine — it's the expected case
     on `helm upgrade` when the database was created on the first install.
   - An actual failure (wrong password, connection refused, PostgreSQL is down,
     network timeout, etc.). This is a real problem that needs retrying.

4. **Distinguish between those two cases.** The `if` block runs a second `psql`
   command that queries the `pg_database` system catalog:
   ```sql
   SELECT 1 FROM pg_database WHERE datname='sonataflow'
   ```
   - If this returns `1`, the database exists. The `grep -q 1` succeeds, and we
     print `"Database 'sonataflow' already exists, skipping creation."` and exit 0.
     Kubernetes sees success. The Job is done.
   - If this returns nothing (or the second `psql` itself fails because the server
     is unreachable), `grep -q 1` fails, and we fall to the `else` branch:
     print `"ERROR: Failed to create database 'sonataflow'."` and `exit 1`.
     Kubernetes sees a failure and retries up to `backoffLimit` times.

There are two versions of this logic in the template — one for the built-in
PostgreSQL (`upstream.postgresql.enabled = true`) that connects directly with
`-U postgres`, and one for external databases that uses environment variables
(`${POSTGRES_HOST}`, `${POSTGRES_PORT}`, `${POSTGRES_USER}`) and connects to
`-d postgres` (the standard maintenance database that always exists on any
PostgreSQL server).

We also made `backoffLimit` configurable via
`orchestrator.sonataflowPlatform.dbCreationJobBackoffLimit` (default: 2, range:
0-10) so users can tune retry behavior for their environment.

---

## Problem 2: Upgrading breaks because Kubernetes Jobs are immutable

### What was happening

Kubernetes Jobs have an immutable `spec.template` — once a Job is created, you
cannot change its pod template. When we changed the `args` (from the old
`|| echo WARNING` to the new error handling), `helm upgrade` tries to patch
the existing Job with the new spec. Kubernetes rejects this:

```
Job.batch "my-backstage-create-sonataflow-database" is invalid:
spec.template: Invalid value: ... field is immutable
```

This means any user upgrading from the old chart to the new chart would hit this
error and the upgrade would fail.

### What we changed: `ttlSecondsAfterFinished`

We added `ttlSecondsAfterFinished: 300` to the Job spec:

```yaml
spec:
  ttlSecondsAfterFinished: 300
  activeDeadlineSeconds: 120
```

This tells Kubernetes to automatically delete the Job 300 seconds (5 minutes)
after it completes. This is a native Kubernetes feature — the TTL controller
watches for completed Jobs and garbage-collects them after the specified time.
No deployment tool needs to understand or honor it; Kubernetes does it on its own.

The flow on upgrade:

1. User installs the chart — Job runs, creates the database, completes
2. 5 minutes later — Kubernetes deletes the completed Job automatically
3. User runs `helm upgrade` (or ArgoCD syncs) — no old Job exists, so the new
   Job is created fresh with the updated spec. No immutability error.

### Why TTL matters for ArgoCD and other GitOps tools

ArgoCD and other GitOps platforms (Flux, etc.) work differently from Helm CLI.
They render Helm templates into plain YAML, then apply that YAML to the cluster
using `kubectl apply`. They do **not** use Helm's lifecycle features like hooks
(explained in Problem 3 below). This means ArgoCD has no built-in way to delete
an old Job before creating a new one.

`ttlSecondsAfterFinished` solves this because it works at the Kubernetes level,
not the deployment tool level. After 5 minutes, the Job is gone regardless of
whether you used Helm, ArgoCD, Flux, or `kubectl apply` directly. When the next
sync happens, the Job doesn't exist, so ArgoCD creates it fresh — no conflict.

### Why this worked fine in our OCP testing

When we tested on OCP, we ran 5 tests:

1. **Fresh install** — Created the Job fresh with the new chart. No old Job
   existed, so there was nothing to conflict with.
2. **TTL cleanup** — The Job auto-deleted after 5 minutes. Confirmed working.
3. **Upgrade after TTL** — By the time we ran `helm upgrade`, the TTL had
   already cleaned up the old Job. The upgrade created a new Job from scratch.
4. **Failure retry** — We manually deleted the Job, then applied a new one with
   bad credentials. Again, no old Job to conflict with.
5. **Schema validation** — Just tested `helm template`, no cluster interaction.

In every case, the old Job was **gone** before the new one was created. We never
actually tested the scenario where an old Job (from the old chart, without TTL)
is still sitting on the cluster when the upgrade runs. That's the scenario CI
tests, and it's the one that fails.

### Upgrade note for users on release 1.8/1.9

The old chart did NOT have `ttlSecondsAfterFinished`, so the old completed Job
will still be sitting on the cluster indefinitely. On the **first** upgrade to
this version, users need to manually delete the old Job:

```bash
kubectl delete job <release-name>-create-sonataflow-database -n <namespace>
```

After that first upgrade, TTL handles cleanup automatically for all future
upgrades.

---

## Problem 3: CI was failing — the old-to-new upgrade race condition

### What the CI test does

The CI uses a tool called `chart-testing` (`ct`) that tests backward
compatibility. It does this:

1. Install the **old** chart (from the `main` branch, version 5.14.0)
2. Run tests to verify the install works
3. Upgrade to the **new** chart (from the PR branch, version 5.14.1)
4. Run tests to verify the upgrade works

The goal is to catch breaking changes — if an upgrade from the current released
version to the new version fails, that's a problem for real users.

### Why it failed

Here's the exact timeline from the CI logs:

- **15:54:06** — `helm install` with the old chart (v5.14.0). This creates the
  Job with the old `|| echo WARNING` args and **no `ttlSecondsAfterFinished`**.
- **15:56:55** — `helm upgrade` with the new chart (v5.14.1). Only ~3 minutes
  later. Helm tries to patch the existing Job with the new multi-line error
  handling args.
- **15:56:57** — Kubernetes rejects: `spec.template: Invalid value: ... field
  is immutable`

Two things made TTL unable to help here:

1. **The old Job has no TTL.** `ttlSecondsAfterFinished` is set at Job creation
   time. The old chart didn't have it, so the Job created in step 1 will sit
   there forever until someone manually deletes it. The new chart adding TTL
   doesn't retroactively apply to Jobs created by the old chart.

2. **Even if TTL were set, 300 seconds > 170 seconds.** The CI upgrade happens
   ~3 minutes after install. Even if the old Job had `ttlSecondsAfterFinished:
   300`, it wouldn't have been cleaned up in time.

### What we changed: Helm hook annotations

We added two annotations to the Job:

```yaml
metadata:
  name: {{ .Release.Name }}-create-sonataflow-database
  namespace: {{ .Release.Namespace }}
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-delete-policy": before-hook-creation
```

### What are annotations?

Annotations are key-value metadata you can attach to any Kubernetes resource.
They look like this in YAML:

```yaml
metadata:
  annotations:
    "some-key": "some-value"
```

Unlike labels (which Kubernetes uses for selecting and grouping resources),
annotations are purely informational — Kubernetes itself ignores them. They're
used by external tools to attach instructions to resources. In this case, Helm
reads these specific annotation keys to decide how to handle the resource.

### What are Helm hooks?

Normally, when you run `helm install` or `helm upgrade`, Helm creates all the
resources in your chart at the same time — Deployments, Services, ConfigMaps,
Jobs, everything goes to the cluster together.

Helm hooks change this. When a resource has the `helm.sh/hook` annotation, Helm
treats it differently — it pulls it out of the normal release and runs it at a
specific point in Helm's lifecycle. Think of it like telling Helm: "Don't deploy
this with everything else. Instead, run it at this specific moment."

### The two annotations explained

**`"helm.sh/hook": post-install,post-upgrade`**

This tells Helm: "This Job is a hook. Run it at these specific moments:
- `post-install` — after all normal resources are created during `helm install`
- `post-upgrade` — after all normal resources are updated during `helm upgrade`

Without this annotation, the Job is just another resource in the chart. Helm
would try to create it on install and patch it on upgrade (which fails because
of immutability). With this annotation, Helm knows to handle it specially.

**`"helm.sh/hook-delete-policy": before-hook-creation`**

This tells Helm: "Before creating this hook resource, delete any previous
version of it that might still exist on the cluster."

This is the key part that fixes the CI failure. The sequence becomes:

1. `helm install` (old chart) — Job is created with old args
2. `helm upgrade` (new chart) — Helm sees the `before-hook-creation` policy,
   **deletes the old Job first**, then creates the new Job with the new args

No patching. No immutability error. The old Job is gone before the new one
is created.

### Why annotations don't help ArgoCD

ArgoCD renders Helm templates into plain YAML (`helm template`) and then applies
that YAML to the cluster using its own sync mechanism. It does **not** run
`helm install` or `helm upgrade`. This means:

- ArgoCD never reads `helm.sh/hook` — it doesn't know what Helm hooks are
- ArgoCD treats the Job as a regular resource, just like a Deployment or Service
- When the Job spec changes, ArgoCD tries to apply the new spec to the existing
  Job — and hits the same immutability error

This is why we need **both** mechanisms:
- Annotations for Helm CLI users and CI
- TTL for ArgoCD and other GitOps tools

---

## How we're catering for everything

We now have a layered solution that covers every deployment scenario:

### Layer 1: Correct error handling (the core fix)

The conditional `psql` logic replaces `|| echo WARNING` with proper error
detection. The Job now:
- Succeeds on fresh database creation (exit 0)
- Succeeds when the database already exists (exit 0)
- Fails on actual errors — wrong credentials, connection refused, etc. (exit 1)
- Retries up to `backoffLimit` times on failure (configurable, default 2)

This is what the Jira ticket (RHDHBUGS-2577) asked for.

### Layer 2: Helm hook annotations (for Helm CLI and CI)

```yaml
annotations:
  "helm.sh/hook": post-install,post-upgrade
  "helm.sh/hook-delete-policy": before-hook-creation
```

Helm deletes the old Job before creating the new one on every upgrade. This:
- Fixes the CI `chart-testing` upgrade test
- Makes `helm upgrade` work for all Helm CLI users, even immediately after
  install (no need to wait for TTL)
- Handles the old-to-new upgrade path (from chart versions that didn't have TTL)

### Layer 3: TTL auto-cleanup (for ArgoCD and other GitOps tools)

```yaml
spec:
  ttlSecondsAfterFinished: 300
```

Kubernetes deletes the completed Job after 5 minutes. This:
- Handles ArgoCD, Flux, and any tool that ignores Helm hooks
- Works at the Kubernetes level — no deployment tool needs to understand it
- Prevents stale Jobs from accumulating on the cluster
- Makes all future syncs/upgrades work automatically (as long as 5+ minutes
  have passed since the last Job completed)

### Layer 4: Configurable backoffLimit (user flexibility)

```yaml
orchestrator.sonataflowPlatform.dbCreationJobBackoffLimit: 2  # default, range 0-10
```

Users can tune how many times Kubernetes retries the Job on failure. The JSON
schema validates the range (0-10) and type (integer).

### Layer 5: Documentation (for the one-time old-to-new upgrade)

For users upgrading from charts that had neither TTL nor hooks (releases 1.8/1.9),
the upgrade instructions document the one manual step needed:

```bash
kubectl delete job <release-name>-create-sonataflow-database -n <namespace>
```

This is only needed once. After that first upgrade, layers 2 and 3 handle
everything automatically.

---

## Summary of all changes

| Change                                                         | Who it helps                                    |
| -------------------------------------------------------------- | ----------------------------------------------- |
| Replace `|| echo WARNING` with conditional error handling      | Everyone — Job now fails on real errors          |
| Distinguish "database already exists" from actual failures     | Everyone — upgrades succeed when DB exists        |
| Make `backoffLimit` configurable (`dbCreationJobBackoffLimit`) | Users who need custom retry behavior              |
| Add `ttlSecondsAfterFinished: 300`                             | ArgoCD / GitOps users — auto-cleanup on upgrade  |
| Add `helm.sh/hook` annotations                                | Helm CLI users and CI — immediate upgrade support |
| Connect to `-d postgres` for external DB                       | External DB users — uses maintenance DB           |

---

## Upgrade instructions for users on release 1.8/1.9

### Before upgrading

The old chart does not have `ttlSecondsAfterFinished` or Helm hook annotations,
so the completed Job from your previous install is still on the cluster. Helm
CLI users with the new hook annotations will have this handled automatically.
ArgoCD users must delete the old Job manually before syncing.

**Step 1: Check if the old Job exists**

```bash
kubectl get job <release-name>-create-sonataflow-database -n <namespace>
```

Replace `<release-name>` with your Helm release name (e.g. `my-backstage`) and
`<namespace>` with your deployment namespace.

If you see output like this, the old Job exists and must be deleted:

```
NAME                                      STATUS     COMPLETIONS   DURATION   AGE
my-backstage-create-sonataflow-database   Complete   1/1           27s        5d
```

If you get `NotFound`, the Job is already gone and you can skip to Step 3.

**Step 2: Delete the old Job**

```bash
kubectl delete job <release-name>-create-sonataflow-database -n <namespace>
```

This is safe — the Job already completed its work (the database was created).
Deleting the Job removes the Job object and its completed pods from the cluster.
It does NOT affect the database.

**Step 3: Upgrade the chart**

```bash
helm upgrade <release-name> redhat-developer/backstage \
  -n <namespace> \
  --reuse-values
```

Or if you're using a local checkout:

```bash
helm upgrade <release-name> ./charts/backstage \
  -n <namespace> \
  --reuse-values
```

The new chart will create a fresh Job with the updated error handling. After this
upgrade, both `ttlSecondsAfterFinished: 300` and the Helm hook annotations will
be set, so all future upgrades will work automatically without manual
intervention.

### For ArgoCD users

If ArgoCD manages your deployment:

1. Delete the old Job manually (Step 2 above)
2. Trigger a sync in ArgoCD

ArgoCD will create the new Job with the updated spec. The `ttlSecondsAfterFinished`
will ensure the Job is cleaned up automatically after future syncs.

If you miss the manual deletion step, ArgoCD will show a sync error
(`field is immutable`). Simply delete the Job and re-sync.

---

## OCP test results (2026-05-27)

All 5 tests passed on OCP 4.20 (Kubernetes v1.33):

| Test                                   | Result | Details                                                                                           |
| -------------------------------------- | ------ | ------------------------------------------------------------------------------------------------- |
| 1. Fresh install                       | PASS   | Job completed 1/1, logs show `CREATE DATABASE`, sonataflow DB confirmed in PostgreSQL             |
| 2. TTL auto-cleanup                    | PASS   | Job auto-deleted after 5 minutes (`ttlSecondsAfterFinished: 300` working)                        |
| 3. Upgrade — DB already exists         | PASS   | Upgrade succeeded, logs show `Database 'sonataflow' already exists, skipping creation.`          |
| 4. Failure retry with bad credentials  | PASS   | 3 pods created (backoffLimit=2), each logged `ERROR: Failed to create database`, Job status=Failed |
| 5. Schema validation                   | PASS   | Helm rejects `-1` (minimum), `11` (maximum), and `abc` (wrong type) for backoffLimit             |

Note: These tests did not cover the old-to-new upgrade path (installing from
`main` then upgrading to the PR branch without deleting the Job). That's the
scenario the CI tests, and it required the Helm hook annotations to fix.

---

## Step-by-step manual testing guide

These steps let you reproduce all three problems and verify the fixes on any
Kubernetes or OpenShift cluster.

### Prerequisites

- A Kubernetes (1.27+) or OpenShift (4.14+) cluster
- `helm` v3.x installed
- `kubectl` or `oc` CLI logged in with cluster-admin access
- SonataFlow and Knative CRDs installed (the Orchestrator requires them)

**Install CRDs if not present:**

```bash
# Knative CRDs (from the chart repo)
for crdDir in charts/orchestrator-infra/crds/*; do
  kubectl apply -f "${crdDir}"
done

# SonataFlow CRDs
SONATAFLOW_OPERATOR_VERSION="10.1.0"
curl -sL "https://github.com/apache/incubator-kie-tools/releases/download/${SONATAFLOW_OPERATOR_VERSION}/apache-kie-${SONATAFLOW_OPERATOR_VERSION}-incubating-sonataflow-operator.yaml" \
  | kubectl apply --server-side --force-conflicts -f -
```

**Create a test namespace:**

```bash
kubectl create namespace sf-test
```

---

### Test 1: Fresh install — verify error handling works

This test verifies the Job creates the database successfully on a fresh install.

```bash
# 1. Build chart dependencies
helm dependency build ./charts/backstage/

# 2. Install the chart with orchestrator enabled
helm install my-backstage ./charts/backstage \
  --namespace sf-test \
  --set orchestrator.enabled=true \
  --set route.enabled=false \
  --set upstream.postgresql.primary.persistence.enabled=true \
  --timeout 500s \
  --wait

# 3. Check the Job completed
kubectl get jobs -n sf-test
# Expected: STATUS = Complete, COMPLETIONS = 1/1

# 4. Check the logs
kubectl logs -n sf-test -l job-name=my-backstage-create-sonataflow-database -c psql
# Expected: "CREATE DATABASE"

# 5. Verify the database exists in PostgreSQL
kubectl exec -n sf-test my-backstage-postgresql-0 -- \
  psql -U postgres -tc "SELECT datname FROM pg_database WHERE datname='sonataflow';"
# Expected: "sonataflow"

# 6. Check TTL is set
kubectl get job my-backstage-create-sonataflow-database -n sf-test \
  -o jsonpath='{.spec.ttlSecondsAfterFinished}'
# Expected: 300

# 7. Check backoffLimit is configurable
kubectl get job my-backstage-create-sonataflow-database -n sf-test \
  -o jsonpath='{.spec.backoffLimit}'
# Expected: 2 (default)

# 8. Check Helm hook annotations are set
kubectl get job my-backstage-create-sonataflow-database -n sf-test \
  -o jsonpath='{.metadata.annotations}'
# Expected: contains "helm.sh/hook":"post-install,post-upgrade" and
#           "helm.sh/hook-delete-policy":"before-hook-creation"
```

---

### Test 2: TTL auto-cleanup

This test verifies the Job is automatically deleted after 5 minutes.

```bash
# 1. Check when the Job completed
kubectl get job my-backstage-create-sonataflow-database -n sf-test \
  -o jsonpath='{.status.completionTime}'
# Note the time

# 2. Wait 5 minutes from the completion time, then check
kubectl get jobs -n sf-test
# Expected: "No resources found" — the Job was garbage-collected
```

---

### Test 3: Upgrade — "database already exists" path

This test verifies that after TTL cleans up the old Job, an upgrade creates
a new Job that gracefully handles the existing database.

```bash
# 1. Make sure the Job was cleaned up by TTL (wait 5 min if needed)
kubectl get jobs -n sf-test
# Expected: "No resources found"

# 2. Run helm upgrade
helm upgrade my-backstage ./charts/backstage \
  --namespace sf-test \
  --set orchestrator.enabled=true \
  --set route.enabled=false \
  --set upstream.postgresql.primary.persistence.enabled=true \
  --timeout 500s \
  --wait
# Expected: Upgrade succeeds

# 3. Check the new Job completed
kubectl get jobs -n sf-test
# Expected: STATUS = Complete, COMPLETIONS = 1/1

# 4. Check the logs — should show "already exists" message
kubectl logs -n sf-test -l job-name=my-backstage-create-sonataflow-database -c psql
# Expected:
#   ERROR:  database "sonataflow" already exists
#   Database 'sonataflow' already exists, skipping creation.
```

---

### Test 4: Upgrade from old chart (simulates 1.8/1.9 user)

This is the most important test. It simulates a user who has the old chart
(with `|| echo WARNING`) and upgrades to the new chart. With the Helm hook
annotations, this should now work automatically.

```bash
# 1. Clean up from previous tests
helm uninstall my-backstage -n sf-test 2>/dev/null
kubectl delete jobs --all -n sf-test 2>/dev/null

# 2. Install the OLD chart from the main branch
git stash                                   # save your current changes
git checkout main -- charts/backstage/      # get the old chart files
helm dependency build ./charts/backstage/

helm install my-backstage ./charts/backstage \
  --namespace sf-test \
  --set orchestrator.enabled=true \
  --set route.enabled=false \
  --set upstream.postgresql.primary.persistence.enabled=true \
  --timeout 500s \
  --wait

# 3. Verify the old Job exists with the old pattern
kubectl get job my-backstage-create-sonataflow-database -n sf-test \
  -o jsonpath='{.spec.template.spec.containers[0].args[0]}'
# Expected: contains "|| echo WARNING: Could not create database"

# 4. Restore your branch
git checkout HEAD -- charts/backstage/      # restore the new chart files
git stash pop                               # restore your local changes
helm dependency build ./charts/backstage/

# 5. Upgrade — with hooks, this should now succeed immediately
helm upgrade my-backstage ./charts/backstage \
  --namespace sf-test \
  --set orchestrator.enabled=true \
  --set route.enabled=false \
  --set upstream.postgresql.primary.persistence.enabled=true \
  --timeout 500s \
  --wait
# Expected: Upgrade SUCCEEDS (Helm deletes old Job via before-hook-creation)

# 6. Verify the new Job has the correct spec
kubectl get job my-backstage-create-sonataflow-database -n sf-test \
  -o jsonpath='{.spec.template.spec.containers[0].args[0]}'
# Expected: contains "SELECT 1 FROM pg_database" (new error handling)

# 7. Check the logs
kubectl logs -n sf-test -l job-name=my-backstage-create-sonataflow-database -c psql
# Expected: "Database 'sonataflow' already exists, skipping creation."
#           OR "CREATE DATABASE" if the DB was lost during pod restart
```

---

### Test 5: Verify retry on actual failure

This test verifies that the Job properly fails and retries when there is a
real error (not just "database already exists").

```bash
# 1. Clean up from previous tests
helm uninstall my-backstage -n sf-test 2>/dev/null
kubectl delete jobs --all -n sf-test 2>/dev/null

# 2. Install with a custom backoffLimit to see retries
helm install my-backstage ./charts/backstage \
  --namespace sf-test \
  --set orchestrator.enabled=true \
  --set route.enabled=false \
  --set upstream.postgresql.primary.persistence.enabled=true \
  --set orchestrator.sonataflowPlatform.dbCreationJobBackoffLimit=3 \
  --timeout 500s \
  --wait

# 3. Verify the backoffLimit was applied
kubectl get job my-backstage-create-sonataflow-database -n sf-test \
  -o jsonpath='{.spec.backoffLimit}'
# Expected: 3
```

To test an actual failure scenario with retries, you would need to make
PostgreSQL unreachable during the Job run (e.g. by scaling down the PostgreSQL
StatefulSet temporarily, or by providing wrong credentials). This is harder to
set up in a simple test but the mechanism is:

- Job fails with exit 1 (the `exit 1` in our error handler)
- Kubernetes creates a new pod to retry
- This repeats up to `backoffLimit` times
- After all retries are exhausted, the Job is marked as Failed

---

### Test 6: Schema validation

This test verifies the JSON schema rejects invalid values for
`dbCreationJobBackoffLimit`.

```bash
# Negative value — should fail
helm template my-backstage ./charts/backstage \
  --set orchestrator.enabled=true \
  --set orchestrator.sonataflowPlatform.dbCreationJobBackoffLimit=-1
# Expected: "minimum: got -1, want 0"

# Over maximum — should fail
helm template my-backstage ./charts/backstage \
  --set orchestrator.enabled=true \
  --set orchestrator.sonataflowPlatform.dbCreationJobBackoffLimit=11
# Expected: "maximum: got 11, want 10"

# Wrong type — should fail
helm template my-backstage ./charts/backstage \
  --set orchestrator.enabled=true \
  --set orchestrator.sonataflowPlatform.dbCreationJobBackoffLimit=abc
# Expected: "got string, want integer"
```

---

### Cleanup

```bash
helm uninstall my-backstage -n sf-test 2>/dev/null
kubectl delete namespace sf-test
```
