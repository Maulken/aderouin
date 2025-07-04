#!/bin/bash

set -e

# Install Docker
apt update
apt install -y docker.io
usermod -aG docker vagrant
systemctl enable docker
systemctl start docker

# Install k3d
curl -s "https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh" | bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.30.1/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Create k3d cluster
k3d cluster create iot-cluster --api-port 6550 -p "8888:80@loadbalancer"

# Namespaces
kubectl create namespace argocd
kubectl create namespace dev

# Install Argo CD
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

# Install Argo CD CLI
curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
chmod +x argocd
mv argocd /usr/local/bin/
