#!/usr/bin/env bash


function captureSetupNewRHDHDeployment {
  if $use_default; then
    NEW_ENVIRONMENT=true
  else
    echo "Setup for a new RHDH deployment?:"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) NEW_ENVIRONMENT=true; break;;
            No ) NEW_ENVIRONMENT=false; break;;
        esac
    done
  fi
}

function captureRHDHNamespace {
  default="rhdh"
  if [ "$use_default" == true ]; then
    rhdh_workspace="$default"
  else
    read -p "Enter RHDH Operator namespace (default: $default): " value
    if [ -z "$value" ]; then
        rhdh_workspace="$default"
    else
        rhdh_workspace="$value"
    fi
  fi
  RHDH_NAMESPACE=$rhdh_workspace
}

function captureWorkflowNamespace {
  default="rhdh"
  if [ "$use_default" == true ]; then
    workflow_namespace="$default"
  else
    read -p "Enter workflow namespace (default: $default): " value
    if [ -z "$value" ]; then
        workflow_namespace="$default"
    else
        workflow_namespace="$value"
    fi
  fi
  WORKFLOW_NAMESPACE=$workflow_namespace
}

function captureK8sURL {
  url="$(oc whoami --show-server)"
  K8S_CLUSTER_URL=$url
}

function generateBackendSecret {
  BACKEND_SECRET=$(mktemp -u XXXXXXXXXXXXXXXXXXXXXXX)
}

function generateK8sToken {
  sa_namespace="rhdh"
  sa_name="rhdh"
  if [ "$use_default" == false ]; then
    read -p "Which namespace should be used or created to check the SA holding the persistent token? (default: $sa_namespace): "
    if [ -n "$sa_namespace" ]; then
      sa_namespace="$sa_namespace"
    fi

    read -p "What is the name of the SA? (default: $sa_name): " selected_name
    if [ -n "$selected_name" ]; then
      sa_name="$selected_name"
    fi
  fi
  if oc get namespace "$sa_namespace" &> /dev/null; then
    echo "Namespace '$sa_namespace' already exists."
  else
    echo "Namespace '$sa_namespace' does not exist. Creating..."
    oc create namespace "$sa_namespace"
  fi

  if oc get sa -n "$sa_namespace" $sa_name &> /dev/null; then
    echo "ServiceAccount '$sa_name' already exists in '$sa_namespace'."
  else
    echo "ServiceAccount '$sa_name' does not exist in '$sa_namespace'. Creating..."
    oc create sa "$sa_name" -n "$sa_namespace"
  fi

  oc adm policy add-cluster-role-to-user cluster-admin -z $sa_name -n $sa_namespace
  echo "Added cluster-admin role to '$sa_name' in '$sa_namespace'."

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: ${sa_name}
  namespace: ${sa_namespace}
  annotations:
    kubernetes.io/service-account.name: orchestrator
EOF

  K8S_CLUSTER_TOKEN=$(oc -n $sa_namespace get secret/${sa_name} -o jsonpath='{.data.token}' | base64 -d )
}

function captureGitToken {
   if [ -z "$GITHUB_TOKEN" ]; then
    read -s -p "Enter GitHub access token: " value
    echo ""
    GITHUB_TOKEN=$value
  else
    echo "GitHub access token already set."
  fi
}

function captureGitlabToken {
   if [ -z "$GITLAB_TOKEN" ]; then
    read -s -p "Enter Gitlab user access token: " value
    echo ""
    GITLAB_TOKEN=$value
  else
    echo "Gitlab access token already set."
  fi
}

function captureGitlabHost {
   if [ -z "$GITLAB_HOST" ]; then
    read -s -p "Enter Gitlab host name: " value
    echo ""
    GITLAB_HOST=$value
  else
    echo "Gitlab host already set."
  fi
}

function captureGitClientId {
   if [ -z "$GITHUB_CLIENT_ID" ]; then
    read -s -p "Enter GitHub client ID (empty for disabling it): " value
    echo ""
    GITHUB_CLIENT_ID=$value
  else
    echo "GitHub client ID already set."
  fi
}

function captureGitClientSecret {
   if [ -z "$GITHUB_CLIENT_SECRET" ]; then
    read -s -p "Enter GitHub client secret (empty for disabling it): " value
    echo ""
    GITHUB_CLIENT_SECRET=$value
  else
    echo "GitHub client secret already set."
  fi
}

function captureArgoCDNamespace {
  default="openshift-gitops"
  if [ "$use_default" == true ]; then
    argocd_namespace="$default"
  else
    read -p "Enter ArgoCD installation namespace (default: $default): " value

    if [ -z "$value" ]; then
        argocd_namespace="$default"
    else
        argocd_namespace="$value"
    fi
  fi
  ARGOCD_NAMESPACE=$argocd_namespace
}

function captureArgoCDURL {
  argocd_instances=$(oc get argocd -n "$ARGOCD_NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

  if [ -z "$argocd_instances" ]; then
      echo "No ArgoCD instances found in namespace $ARGOCD_NAMESPACE. Continuing without ArgoCD support"
  else
    if [ "$use_default" == true ]; then
          selected_instance=$(echo "$argocd_instances" | awk 'NR==1')
          echo "Select an ArgoCD instance: $selected_instance"
    else
      echo "Select an ArgoCD instance:"
      select instance in $argocd_instances; do
          if [ -n "$instance" ]; then
              selected_instance="$instance"
              break
          else
              echo "Invalid selection. Please choose a valid option."
          fi
      done
    fi
    argocd_route=$(oc get route -n $ARGOCD_NAMESPACE -l app.kubernetes.io/managed-by=$selected_instance -ojsonpath='{.items[0].status.ingress[0].host}')
    echo "Found Route at $argocd_route"
    ARGOCD_URL=https://$argocd_route
  fi

}

function captureArgoCDCreds {
  if [ -n "$selected_instance" ]; then
    admin_password=$(oc get secret -n $ARGOCD_NAMESPACE ${selected_instance}-cluster -ojsonpath='{.data.admin\.password}' | base64 -d)
    ARGOCD_USERNAME=admin
    ARGOCD_PASSWORD=$admin_password
  fi
}

function captureNotificationsEmailHostname {
   if [ -z "$NOTIFICATIONS_EMAIL_HOSTNAME" ]; then
    read -p "Enter the SMTP server hostname for notification emails (empty for disabling it): " value
    echo ""
    NOTIFICATIONS_EMAIL_HOSTNAME=$value
  else
    echo "SMTP server hostname for notification emails already set."
  fi
}

function captureNotificationsEmailUsername {
   if [ -z "$NOTIFICATIONS_EMAIL_USERNAME" ]; then
    read -p "Enter the SMTP server username for notification emails (empty for disabling it): " value
    echo ""
    NOTIFICATIONS_EMAIL_USERNAME=$value
  else
    echo "SMTP server username for notification emails already set."
  fi
}

function captureNotificationsEmailPassword {
   if [ -z "$NOTIFICATIONS_EMAIL_PASSWORD" ]; then
    read -s -p "Enter the SMTP server password for notification emails (empty for disabling it): " value
    echo ""
    NOTIFICATIONS_EMAIL_PASSWORD=$value
  else
    echo "SMTP server password for notification emails already set."
  fi
}

function setupNotificationsEmailConfig {
  if $use_default; then
    if [ -z "${SETUP_NOTIFICATIONS_EMAIL+x}" ]; then
      SETUP_NOTIFICATIONS_EMAIL=false
    fi
  else
    echo "Setup a notifications email plugin?:"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) SETUP_NOTIFICATIONS_EMAIL=true; break;;
            No ) SETUP_NOTIFICATIONS_EMAIL=false; break;;
        esac
    done
  fi
}

function checkPrerequisite {
  if ! command -v oc &> /dev/null; then
    echo "oc is required for this script to run. Exiting."
    exit 1
  fi
}

function createBackstageSecret {
  if 2>/dev/null 1>&2 oc get secret orchestrator-auth-secret -n $RHDH_NAMESPACE; then
    oc delete secret orchestrator-auth-secret -n $RHDH_NAMESPACE
  fi
  declare -A secretKeys
  if [ -n "$K8S_CLUSTER_URL" ]; then
    secretKeys[K8S_CLUSTER_URL]=$K8S_CLUSTER_URL
  fi
  if [ -n "$K8S_CLUSTER_TOKEN" ]; then
    secretKeys[K8S_CLUSTER_TOKEN]=$K8S_CLUSTER_TOKEN
  fi
  if [ -n "$ARGOCD_USERNAME" ]; then
    secretKeys[ARGOCD_USERNAME]=$ARGOCD_USERNAME
  fi
  if [ -n "$ARGOCD_URL" ]; then
    secretKeys[ARGOCD_URL]=$ARGOCD_URL
  fi
  if [ -n "$ARGOCD_PASSWORD" ]; then
    secretKeys[ARGOCD_PASSWORD]=$ARGOCD_PASSWORD
  fi
  if [ -n "$GITHUB_TOKEN" ]; then
    secretKeys[GITHUB_TOKEN]=$GITHUB_TOKEN
  fi
  if [ -n "$GITLAB_TOKEN" ]; then
    secretKeys[GITLAB_TOKEN]=$GITLAB_TOKEN
  fi
  if [ -n "$GITLAB_HOST" ]; then
    secretKeys[GITLAB_HOST]=$GITLAB_HOST
  fi
  if [ -n "$GITHUB_CLIENT_ID" ]; then
    secretKeys[GITHUB_CLIENT_ID]=$GITHUB_CLIENT_ID
  fi
  if [ -n "$GITHUB_CLIENT_SECRET" ]; then
    secretKeys[GITHUB_CLIENT_SECRET]=$GITHUB_CLIENT_SECRET
  fi
  if [ -n "$NOTIFICATIONS_EMAIL_HOSTNAME" ] && [ "$SETUP_NOTIFICATIONS_EMAIL" = true ]; then
    secretKeys[NOTIFICATIONS_EMAIL_HOSTNAME]=$NOTIFICATIONS_EMAIL_HOSTNAME
  fi
  if [ -n "$NOTIFICATIONS_EMAIL_USERNAME" ] && [ "$SETUP_NOTIFICATIONS_EMAIL" = true ]; then
    secretKeys[NOTIFICATIONS_EMAIL_USERNAME]=$NOTIFICATIONS_EMAIL_USERNAME
  fi
  if [ -n "$NOTIFICATIONS_EMAIL_PASSWORD" ] && [ "$SETUP_NOTIFICATIONS_EMAIL" = true ]; then
    secretKeys[NOTIFICATIONS_EMAIL_PASSWORD]=$NOTIFICATIONS_EMAIL_PASSWORD
  fi
  cmd="oc create secret generic orchestrator-auth-secret -n $RHDH_NAMESPACE --from-literal=BACKEND_SECRET=$BACKEND_SECRET"
  for key in "${!secretKeys[@]}"; do
    cmd="${cmd} --from-literal=${key}=${secretKeys[$key]}"
  done
  eval $cmd
}

function labelNamespaces {
  for a in $(oc get namespace -l rhdh.redhat.com/workflow-namespace -oname); do
    oc label $a rhdh.redhat.com/workflow-namespace- ;
  done
  for a in $(oc get namespace -l rhdh.redhat.com/argocd-namespace -oname); do
    oc label $a rhdh.redhat.com/argocd-namespace- ;
  done
  if [ -n "$WORKFLOW_NAMESPACE" ]; then
    oc label namespace $WORKFLOW_NAMESPACE rhdh.redhat.com/workflow-namespace=
  fi
  if [[ -n "$ARGOCD_NAMESPACE" && -n "$ARGOCD_PASSWORD" && -n "$ARGOCD_URL" && -n "$ARGOCD_USERNAME" ]]; then
    oc label namespace $ARGOCD_NAMESPACE rhdh.redhat.com/argocd-namespace=
  fi
}

# Function to display usage instructions
display_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help        Display usage instructions"
    echo "  --use-default     Specify to use all default values"
    exit 1
}

# Initialize variable
use_default=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            display_usage
            ;;
        --use-default)
            use_default=true
            ;;
        *)
            echo "Error: Invalid option $1"
            display_usage
            ;;
    esac
    shift
done

function main {

  # Check if using default values or not
  if $use_default; then
      echo "Using default values."
  else
      echo "Not using default values."
  fi

  checkPrerequisite
  captureSetupNewRHDHDeployment
  captureWorkflowNamespace
  captureArgoCDNamespace
  captureArgoCDURL
  captureArgoCDCreds
  labelNamespaces
  if $NEW_ENVIRONMENT; then
    generateBackendSecret
    captureK8sURL
    generateK8sToken
    captureGitToken
    captureGitClientId
    captureGitClientSecret
    captureGitlabHost
    captureGitlabToken
    setupNotificationsEmailConfig
    if $SETUP_NOTIFICATIONS_EMAIL; then
      captureNotificationsEmailHostname
      captureNotificationsEmailUsername
      captureNotificationsEmailPassword
    fi
    captureRHDHNamespace
    createBackstageSecret
  fi
  echo "Setup completed successfully!"
}

main

