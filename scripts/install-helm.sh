#!/bin/bash

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
        ROUTER_BASE=$($CLI get route -n default | grep -m1 'console' | awk '{print $2}')
    else
        ROUTER_BASE=$($CLI get ingress -A | grep -m1 'default' | awk '{print $4}')
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
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Update Helm chart with the detected or provided router base
echo "Using router base: $ROUTER_BASE"
# Assuming you have a values.yaml or similar configuration for the Helm chart
sed -i "s|routerBase:.*|routerBase: $ROUTER_BASE|" path/to/helm/values.yaml

# Proceed with Helm installation
helm install my-release path/to/helm/chart --values path/to/helm/values.yaml

echo "Helm installation completed successfully."
