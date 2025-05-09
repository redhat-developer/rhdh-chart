#!/bin/bash
# install a helm chart with the correct global.clusterRouterBase

# default namespace if none set
namespace="rhdh-helm"
# chartrepo=0 # by default don't create a new chart repo unless the version chart version includes "CI" suffix

usage ()
{
  echo "Usage: $0 CHART_VERSION [-n namespace]

Examples:
  $0 1.5.1 
  $0 1.7-20-CI -n rhdh-ci

Options:
  -n, --namespace   Project or namespace into which to install specified chart; default: $namespace
      --github-repo If set will use the deprecated github repository to install the helm chart instead of the OCI registry.
      --router      If set, the cluster router base is manually set. 
                    Required for non-admin users
                    Redundant for admin users
"
      # --chartrepo   If set, a Helm Chart Repo will be applied to the cluster, based on the chart version.
      #               If CHART_VERSION ends in CI, this is done by default.
}

if [[ $# -lt 1 ]]; then usage; exit 0; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    # '--chartrepo') chartrepo=1;;
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

# choose namespace for the install (or create if non-existant)
oc new-project "$namespace" || oc project "$namespace"

# TODO: RHIDP-6668 generate rhdh-next-ci-repo.yaml while installing so we don't have to publish a new file every time
# TODO: RHIDP-6668 publish an index.yaml with every tarball pushed to quay.io/rhdh/chart; save them in rhdh-chart repo (one per CI versioned branch)
# if [[ "$CV" == *"-CI" ]] || [[ $chartrepo -eq 1 ]]; then
# see samples at 
# https://github.com/rhdh-bot/openshift-helm-charts/blob/rhdh-1-rhel-9/installation/index.yaml#L19
# https://github.com/rhdh-bot/openshift-helm-charts/blob/rhdh-1-rhel-9/installation/index.yaml#L49-L50
# https://github.com/rhdh-bot/openshift-helm-charts/blob/rhdh-1-rhel-9/installation/rhdh-next-ci-repo.yaml#L8
#     oc apply -f https://github.com/redhat-developer/rhdh-chart/raw/redhat-developer-hub-"${CV}"/installation/rhdh-next-ci-repo.yaml
# fi

# 1. install (or upgrade)
helm upgrade redhat-developer-hub -i "${CHART_URL}" --version "$CV"

# 2. collect values
PASSWORD=$(kubectl get secret redhat-developer-hub-postgresql -o jsonpath="{.data.password}" | base64 -d)
if [[ $(oc auth can-i get route/openshift-console) == "yes" ]]; then
  CLUSTER_ROUTER_BASE=$(oc get route console -n openshift-console -o=jsonpath='{.spec.host}' | sed 's/^[^.]*\.//')
elif [[ -z $CLUSTER_ROUTER_BASE ]]; then
  echo "Error: openshift-console routes cannot be accessed with user permissions"
  echo "Rerun command installation script with --router <cluster router base>"
  echo
  usage
  exit 1
fi

# 3. change values
helm upgrade redhat-developer-hub -i "${CHART_URL}" --version "$CV" \
    --set global.clusterRouterBase="${CLUSTER_ROUTER_BASE}" \
    --set global.postgresql.auth.password="$PASSWORD"

echo "
Once deployed, Developer Hub $CV will be available at
https://redhat-developer-hub-${namespace}.${CLUSTER_ROUTER_BASE}
"