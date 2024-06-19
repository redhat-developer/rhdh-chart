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
# Script to handle CLI helm installation for k8s and OCP
#
# Requires: oc or kubectl

usage() {
echo "
This script simplifies and automates the installation process of Helm charts on Kubernetes (K8s) and OpenShift Container Platform (OCP) clusters.
It detects whether 'oc' or 'kubectl' is installed and ensures that the user is logged into a cluster.
The script also attempts to detect the cluster router base and updates the Helm chart configuration accordingly.

Usage:
  $0 [OPTIONS]

Options:
  --router-base <router-base>  : Manually provide the cluster router base if auto-detection fails.
  --help                       : Show this help message and exit.

Examples:
  $0                               # Auto-detects router base and installs the Helm chart
  $0 --router-base example.com     # Manually specifies the router base and installs the Helm chart
"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if either oc or kubectl is installed
if command_exists oc; then
    CLI="oc"
elif command_exists kubectl; then
    CLI="kubectl"
else
    echo "Error: Neither 'oc' nor 'kubectl' is installed. Please install one of them to proceed."
    exit 1
fi

# Check if the user is logged into a cluster
if ! $CLI whoami >/dev/null 2>&1; then
    echo "Error: You are not logged into a cluster. Please log in using '$CLI login' or '$CLI config set-context'."
    exit 1
fi

# Function to detect cluster router base
detect_cluster_router_base() {
    if [ "$CLI" == "oc" ]; then
        ROUTER_BASE=$($CLI get route -n openshift-console -o=jsonpath='{.items[0].spec.host}')
    else
        ROUTER_BASE=$($CLI get ingress -n default -o=jsonpath='{.items[0].spec.rules[0].host}')
    fi
}

# Detect cluster router base
detect_cluster_router_base

# If detection fails, prompt user for input
if [ -z "$ROUTER_BASE" ]; then
    echo "Error: Cluster router base could not be detected. Please provide it using the --router-base flag."
    exit 1
fi

# Parse command-line arguments for optional router base
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --router-base) ROUTER_BASE="$2"; shift ;;
        --help) usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Update Helm chart with the detected or provided router base
echo "Using router base: $ROUTER_BASE"
# Define the path to values.yaml
VALUES_FILE="../charts/backstage/values.yaml"
if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: values.yaml file not found at $VALUES_FILE"
    exit 1
fi
sed -i "s|routerBase:.*|routerBase: $ROUTER_BASE|" "$VALUES_FILE"

# Define the path to the Helm chart directory
HELM_CHART_DIR="../charts/backstage"
if [ ! -d "$HELM_CHART_DIR" ]; then
    echo "Error: Helm chart directory not found at $HELM_CHART_DIR"
    exit 1
fi

# Proceed with Helm installation
helm install my-release "$HELM_CHART_DIR" --values "$VALUES_FILE"

echo "Helm installation completed successfully."
