#!/bin/bash

set -e

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.30.1/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install Argo CD CLI
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Create k3d cluster
k3d cluster create iot-cluster --api-port 6550 -p "8888:80@loadbalancer"

# Create namespaces
kubectl create namespace argocd
kubectl create namespace dev
kubectl create namespace gitlab

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s


# Port-forward Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

# Attendre que l'interface soit dispo
until curl -k https://localhost:8080 > /dev/null 2>&1; do
  sleep 2
done

# Port-forward Argo CD UI
#kubectl port-forward svc/argocd-server -n argocd 8080:80 &

# Wait briefly for port-forward to take effect
#sleep 5

# Get Argo CD admin password
echo "Argo CD Admin password:"
echo -e "\e[32m$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)\e[0m"

# 🔐 Log in to Argo CD CLI
argocd login localhost:8080 \
  --username admin \
  --password $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d) \
  --insecure

# ➕ Add GitLab repository (private repo access)
#argocd repo add https://gitlab.com/iot-group3/iot.git \
#  --username aldeau \
#  --password your-access-token

# 🚀 Create Argo CD application
argocd app create playground \
  --repo https://gitlab.com/vmassoli-group/iot.git \
  --path bonus/iot/app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

# 🔄 Enable auto-sync
argocd app set playground \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# ⏱️ Trigger initial sync
argocd app sync playground

