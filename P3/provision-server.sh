# _____________________________
# commade pour recupere le mdp
# kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
# _____________________________

#sudo apt update && sudo apt install -y docker.io
#sudo usermod -aG docker $USER
#newgrp docker  # or logout/login

sudo apt install curl

# Install k3d and kubectl (assuming docker installed & ready)
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

curl -LO "https://dl.k8s.io/release/v1.30.1/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Create cluster with loadbalancer forwarding port 80 -> 8888
k3d cluster create iot-cluster --api-port 6550 -p "8888:80@loadbalancer"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for argocd-server deployment to be ready (timeout 5 mins)
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

# Then port-forward (in background if needed)
kubectl port-forward svc/argocd-server -n argocd 8080:80 &