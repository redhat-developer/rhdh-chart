#!/bin/bash
# install a helm chart with the correct global.clusterRouterBase

# default namespace if none set
namespace="rhdh-helm"
# chartrepo=0 # by default don't create a new chart repo unless the version chart version includes "CI" suffix

usage ()
{
  echo "Usage: $0 CHART_VERSION [-n namespace]

Requires an existing connection to an OCP or k8s cluster
Requires helm, plus oc or kubectl, to be installed and on the path

Examples:
  $0 1.5.1 
  $0 1.7-zzz-CI -n rhdh-ci

Options:
  -n, --namespace   Project or namespace into which to install specified chart; default: $namespace
      --chartrepo   If set, a Helm Chart Repo will be applied to the cluster, based on the chart version.
                    If CHART_VERSION ends in CI, this is done by default.
      --router      If set, the cluster router base is manually set. 
                    Required for non-admin users
                    Redundant for admin users
"
}

if [[ $# -lt 1 ]]; then usage; exit 0; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--chartrepo') chartrepo=1;;
    '-n'|'--namespace') namespace="$2"; shift 1;;
    '-h') usage; exit 0;;
    '--router') CLUSTER_ROUTER_BASE="$2"; shift 1;;
    *) CV="$1";;
  esac
  shift 1
done

if [[ ! "$CV" ]]; then usage; exit 1; fi

CHART_URL="oci://quay.io/rhdh/chart"

if ! helm show chart $CHART_URL --version "$CV" &> /dev/null; then 
  echo "Error: could not load chart $CV from $CHART_URL !"
  echo
  usage
  exit 1
  fi

echo "Using ${CHART_URL} to install Helm chart"

# choose namespace for the install (or create if non-existent)
oc new-project "$namespace" || oc project "$namespace"

# generate repo.yaml and index.yaml so we don't have to publish a new file every time
if [[ "$CV" == *"-CI" ]] || [[ $chartrepo -eq 1 ]]; then
  mkdir -p /tmp/"$CV"-unpacked && pushd /tmp/"$CV"-unpacked >/dev/null 2>&1 || exit 1
  helm pull oci://quay.io/rhdh/chart --version "$CV" -d /tmp/"$CV"-unpacked # get tarball
  helm repo index /tmp/"$CV"-unpacked # create index.yaml

  # HelmChartRepository does not support OCI artifacts.
  # Host an in-cluster Helm repo serving both the index and chart files.
  if oc -n "$namespace" get configmap helm-repo-files > /dev/null; then
    oc -n "$namespace" delete configmap helm-repo-files
  fi
  oc -n "$namespace" create configmap helm-repo-files \
    --from-file=/tmp/"$CV"-unpacked/index.yaml \
    --from-file="/tmp/$CV-unpacked/chart-${CV}.tgz"
  cat <<EOF > helm-repo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helm-repo
  annotations:
    rhdh.redhat.com/chart-version: "$CV"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helm-repo
  template:
    metadata:
      labels:
        app: helm-repo
      annotations:
        rhdh.redhat.com/chart-version: "$CV"
    spec:
      containers:
      - name: nginx
        image: quay.io/openshifttest/nginx-alpine:1.2.4
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: chart-vol
          mountPath: /data/http/charts
      volumes:
      - name: chart-vol
        configMap:
          name: helm-repo-files
---
apiVersion: v1
kind: Service
metadata:
  name: helm-repo
spec:
  selector:
    app: helm-repo
  ports:
  - port: 80
    targetPort: 8080
EOF
  oc apply -f helm-repo.yaml || kubectl apply -f helm-repo.yaml

  cat <<EOF > repo.yaml
apiVersion: helm.openshift.io/v1beta1
kind: HelmChartRepository
metadata:
  name: rhdh-next-ci-repo
  annotations:
    rhdh.redhat.com/chart-version: "$CV"
spec:
  connectionConfig:
    url: http://helm-repo.${namespace}.svc.cluster.local/charts
EOF

  oc apply -f repo.yaml || kubectl apply -f repo.yaml
  popd  >/dev/null 2>&1 || exit 1

  # clean up temp files
  rm -fr /tmp/"$CV"-unpacked
fi

if [[ $(oc auth can-i get route/openshift-console) == "yes" ]]; then
  CLUSTER_ROUTER_BASE=$(oc get route console -n openshift-console -o=jsonpath='{.spec.host}' | sed 's/^[^.]*\.//')
elif [[ -z $CLUSTER_ROUTER_BASE ]]; then
  echo "Error: openshift-console routes cannot be accessed with user permissions"
  echo "Rerun command installation script with --router <cluster router base>"
  echo
  usage
  exit 1
fi

# change values
helm upgrade redhat-developer-hub -i "${CHART_URL}" --version "$CV" \
    --set global.clusterRouterBase="${CLUSTER_ROUTER_BASE}"

echo "
While deploying you can watch at 
https://console-openshift-console.${CLUSTER_ROUTER_BASE}/topology/ns/${namespace}?view=graph
"
echo "
Once deployed, Developer Hub $CV will be available at
https://redhat-developer-hub-${namespace}.${CLUSTER_ROUTER_BASE}
"
