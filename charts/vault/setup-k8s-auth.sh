#!/bin/bash
set -e

# Variables
VAULT_ADDR=${VAULT_ADDR:-"https://vault.lab.local:8200"}
VAULT_TOKEN=${VAULT_TOKEN:-""}
K8S_HOST=${K8S_HOST:-"https://192.168.1.101:6443"}
NAMESPACE=${NAMESPACE:-"default"}
SERVICE_ACCOUNT=${SERVICE_ACCOUNT:-"vault-auth"}
VAULT_LEADER=${VAULT_LEADER:-"192.168.1.240"}

# Try to get root token if not provided
if [ -z "$VAULT_TOKEN" ]; then
    echo "VAULT_TOKEN not provided, attempting to retrieve from Vault leader..."
    if command -v sshpass &> /dev/null && [ ! -z "$VAULT_SSH_PASS" ]; then
        ROOT_TOKEN=$(sshpass -p "$VAULT_SSH_PASS" ssh root@$VAULT_LEADER "cat /root/vault-init.json | jq -r .root_token 2>/dev/null || echo ''")
        if [ ! -z "$ROOT_TOKEN" ]; then
            VAULT_TOKEN=$ROOT_TOKEN
            echo "Retrieved root token from Vault leader"
        else
            echo "VAULT_TOKEN environment variable is required but could not be retrieved automatically."
            echo "Example: VAULT_TOKEN='*******' ./charts/vault/setup-k8s-auth.sh"
            exit 1
        fi
    else
        echo "VAULT_TOKEN environment variable is required. Please set it before running this script."
        echo "Example: VAULT_TOKEN='*******' ./charts/vault/setup-k8s-auth.sh"
        exit 1
    fi
fi

echo "Configuring Vault Kubernetes auth..."

# Create service account for Vault auth
kubectl create serviceaccount ${SERVICE_ACCOUNT} -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Create ClusterRoleBinding for the service account
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-token-reviewer-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: ${SERVICE_ACCOUNT}
  namespace: ${NAMESPACE}
EOF

# Get service account JWT token and certificate
SECRET_NAME=$(kubectl get serviceaccount ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[0].name}')
SA_JWT_TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 --decode)
K8S_CACERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)

# Configure Vault
export VAULT_ADDR=${VAULT_ADDR}
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=${VAULT_TOKEN}

# Create kubernetes-admin policy first - this allows managing k8s auth
echo "Creating kubernetes-admin policy..."
cat <<EOF > /tmp/kubernetes-admin-policy.hcl
# Admin policy for managing Kubernetes auth and policies
path "auth/kubernetes/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kubernetes/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOF

# Create the kubernetes-admin policy
vault policy write kubernetes-admin /tmp/kubernetes-admin-policy.hcl || {
    echo "Note: Unable to create kubernetes-admin policy - likely already exists or insufficient permissions"
}

# Check if Kubernetes auth method is already enabled
EXISTING_AUTH=$(vault auth list -format=json 2>/dev/null | jq -r 'has("kubernetes/")')

if [ "$EXISTING_AUTH" != "true" ]; then
    echo "Enabling Kubernetes auth method..."
    vault auth enable kubernetes || {
        echo "Failed to enable Kubernetes auth method. Do you have sufficient permissions?"
        exit 1
    }
fi

# Configure the Kubernetes auth method
echo "Configuring Kubernetes auth method in Vault..."
vault write auth/kubernetes/config \
  kubernetes_host="${K8S_HOST}" \
  kubernetes_ca_cert="${K8S_CACERT}" \
  token_reviewer_jwt="${SA_JWT_TOKEN}" \
  issuer="https://kubernetes.default.svc.cluster.local"

# Create a Vault policy for applications
cat <<EOF > /tmp/app-policy.hcl
path "kubernetes/*" {
  capabilities = ["read"]
}
EOF

vault policy write app-policy /tmp/app-policy.hcl || echo "Warning: Could not create app-policy"

# Create a role for Kubernetes authentication
vault write auth/kubernetes/role/app-role \
  bound_service_account_names="*" \
  bound_service_account_namespaces="default,app" \
  policies="app-policy" \
  ttl=1h

# Create kubernetes-auth role that's referenced in the helm chart
vault write auth/kubernetes/role/kubernetes-auth \
  bound_service_account_names="*" \
  bound_service_account_namespaces="default" \
  policies="kubernetes-access" \
  ttl=1h

echo "Vault Kubernetes auth configuration complete!"
echo "Now you can deploy the Vault Helm chart with: helm install vault hashicorp/vault -f charts/vault/values.yaml"