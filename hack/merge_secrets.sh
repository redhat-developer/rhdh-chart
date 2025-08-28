#!/bin/bash

# The script merges two given K8s secrets in yaml format into a single secret named 'docker-credentials' in 'orchestrator-gitops' namespace.
# This script is required to simplify the instruction of
# https://github.com/rhdhorchestrator/orchestrator-helm-operator/tree/main/docs/gitops#installing-docker-credentials

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <secret1_file> <secret2_file>"
    exit 1
fi

# Read the input arguments
secret1_file=$1
secret2_file=$2

# Function to base64 encode a file
base64_encode() {
    local input_file=$1
    local output_file=$2
    base64 -w 0 "$input_file" > "$output_file"
}

# Decode the secrets into temporary files
temp_secret1_file=$(mktemp)
temp_secret2_file=$(mktemp)

cat "$secret1_file" | yq e '.data[".dockerconfigjson"]' | base64 -d > "$temp_secret1_file"
cat "$secret2_file" | yq e '.data[".dockerconfigjson"]' | base64 -d > "$temp_secret2_file"

# Merge the decoded files
merged_secret_file=$(mktemp)
cat "$temp_secret1_file" "$temp_secret2_file" | jq -s '.[0] * .[1]' > "$merged_secret_file"

# Encode the merged secret back to base64
encoded_merged_secret=$(mktemp)
base64_encode "$merged_secret_file" "$encoded_merged_secret"

# Create the new secret YAML
echo "apiVersion: v1
kind: Secret
metadata:
  name: docker-credentials
  namespace: orchestrator-gitops
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $(cat $encoded_merged_secret)" > docker-credentials-secret.yaml

# Clean up temporary files
rm "$temp_secret1_file" "$temp_secret2_file" "$merged_secret_file" "$encoded_merged_secret"

echo "Merged secret created: docker-credentials-secret.yaml"
