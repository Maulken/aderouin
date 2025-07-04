#!/bin/sh

apk update
apk upgrade
apk add curl

K3S_TOK=$(cat /vagrant_shared/node-token)

while [ ! -f /vagrant_shared/node-token ]; do
  echo "Waiting for node-token..."
  sleep 5
done

# Join the cluster as a worker node
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" \
  INSTALL_K3S_EXEC="--flannel-iface eth1" \
  K3S_URL="https://192.168.56.110:6443" \
  K3S_TOKEN="$K3S_TOK" sh -