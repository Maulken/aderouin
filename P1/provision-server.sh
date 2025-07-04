#!/bin/sh

# Update system
apk update
apk upgrade
apk add curl

# Install K3s in server mode
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --cluster-init \
  --snapshotter=native \
  --write-kubeconfig-mode 644 \
  --flannel-iface eth1" sh -

# Wait for K3s to be ready
echo "Waiting for K3s to start..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

NODE_TOKEN="/var/lib/rancher/k3s/server/node-token"
YML="/etc/rancher/k3s/k3s.yaml"

# Share the token with the worker node
mkdir -p /vagrant_shared
cp ${NODE_TOKEN} /vagrant_shared/node-token
cp ${YML} /vagrant_shared/k3s.yaml

# Wait for kubeconfig to be available
while [ ! -f ${YML} ]; do
  sleep 5
done

# Copy kubeconfig for user 'vagrant'
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config


