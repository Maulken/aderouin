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


kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

#until kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; do
#  sleep 2
#done

#get password
#kubectl get secret argocd-initial-admin-secret -n argocd \
#  -o jsonpath="{.data.password}" | base64 -d > /tmp/argopass


#exposition (ouverture) des ports 
#kubectl port-forward svc/argocd-server -n argocd 8080:443 &
#sleep 10 

# Attendre que le pod argocd-server soit prêt
#kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
until kubectl get pods -n argocd | grep argocd-server | grep -q "1/1"; do
  sleep 2
done

# Récupérer le mot de passe admin
until kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; do
  sleep 2
done
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d > /tmp/argopass

# Install Argo CD CLI
curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
chmod +x argocd
mv argocd /usr/local/bin/

# Lancer le port-forward en arrière-plan
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
sleep 10

# Tester si le port est bien ouvert
until nc -z localhost 8080; do
  sleep 2
done

#connexion CLI argo
argocd login localhost:8080 --username admin --password $(cat /tmp/argopass) --insecure

# Créer l'application Argo CD
argocd app create aderouin \
  --repo https://github.com/Maulken/aderouin \
  --path P3 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

# Synchronisation automatique
argocd app sync aderouin