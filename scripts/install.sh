#!/bin/bash
#
#  Copyright (c) 2024 Red Hat, Inc.
#  Licensed under the Apache License, Version 2.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# Script to handle CLI helm installation for OCP
#
# Requires: oc and an active login session to a cluster.

set -e

usage() {
    echo "
This script simplifies and automates the installation process of Helm charts on the OpenShift Container Platform (OCP) clusters.
It ensures that the user is logged into a cluster and attempts to detect the cluster router base, updating the Helm chart configuration accordingly.

Usage:
  $0 [OPTIONS]

Options:
  --router-base <router-base> : Manually provide the cluster router base if auto-detection fails.
  --release-name <name>       : Specify a custom release name for the Helm chart.
  --generate-name             : Generate a name for the Helm release (overrides --release-name).
  --namespace <namespace>     : Specify the namespace for the Helm release (autodetects if not provided).
  --values <file>             : Specify your own values file for the Helm chart.
  --help                      : Show this help message and exit.

Examples:
  $0                               # Auto-detects router base and installs the Helm chart
  $0 --router-base example.com     # Manually specifies the router base and installs the Helm chart
  $0 --release-name myrelease      # Installs the Helm chart with the specified release name
  $0 --generate-name               # Generates a name for the Helm release
  $0 --values /path/to/values.yaml # Installs the Helm chart using the specified values file
"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
if ! command_exists helm || ! command_exists oc; then
    echo "Error: Required commands 'helm' and 'oc' are not available."
    exit 1
fi

# Check if required files and directories exist
HELM_CHART_DIR="$(dirname "$0")/../charts/backstage"
DEFAULT_VALUES_FILE="$HELM_CHART_DIR/values.yaml"

if [ ! -d "$HELM_CHART_DIR" ]; then
    echo "Error: Helm chart directory not found at $HELM_CHART_DIR"
    exit 1
fi

# Parse command-line arguments
ROUTER_BASE=""
RELEASE_NAME=""
GENERATE_NAME=false
NAMESPACE=""
VALUES_FILE="$DEFAULT_VALUES_FILE"
EXTRA_HELM_ARGS=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --router-base)
            ROUTER_BASE="$2"
            shift
            ;;
        --release-name)
            RELEASE_NAME="$2"
            shift
            ;;
        --generate-name)
            GENERATE_NAME=true
            ;;
        --namespace)
            NAMESPACE="$2"
            shift
            ;;
        --values)
            VALUES_FILE="$2"
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            EXTRA_HELM_ARGS+=" $1"
            ;;
    esac
    shift
done

# Function to detect cluster router base
detect_cluster_router_base() {
    ROUTER_BASE=$(oc get ingress.config.openshift.io/cluster -o=jsonpath='{.spec.domain}')
}

# Detect cluster router base if not provided
if [[ -z "$ROUTER_BASE" ]]; then
    detect_cluster_router_base || (echo "Error: Cluster router base could not be detected. Please provide it using the --router-base flag." && exit 1)
fi

# Detect namespace if not provided
if [[ -z "$NAMESPACE" ]]; then
    NAMESPACE=$(oc config view --minify --output 'jsonpath={..namespace}')
    if [[ -z $NAMESPACE ]]; then
        echo "Error: Namespace could not be detected. Please provide it using the --namespace flag."
        exit 1
    fi
fi

# Update Helm chart with the detected or provided router base if using default values file
if [[ "$VALUES_FILE" == "$DEFAULT_VALUES_FILE" ]]; then
    EXTRA_HELM_ARGS+="--set global.clusterRouterBase=$ROUTER_BASE"
fi

# Construct Helm install command
HELM_CMD="helm install"
if [[ $GENERATE_NAME == true ]]; then
    HELM_CMD+=" --generate-name"
elif [[ -z "$RELEASE_NAME" ]]; then
    echo "Error: Either --release-name must be specified or --generate-name must be used."
    exit 1
else
    HELM_CMD+=" $RELEASE_NAME"
fi

HELM_CMD+=" $HELM_CHART_DIR --values $VALUES_FILE --namespace $NAMESPACE $EXTRA_HELM_ARGS"

# Execute Helm install command
echo "Executing: $HELM_CMD"

if eval "$HELM_CMD"; then
    echo "Helm installation completed successfully."
else
    echo "Something went wrong with Helm installation!"
    exit 1
fi