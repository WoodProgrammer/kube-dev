#!/bin/bash
set -e

export INSTANCE_ROLE=${instance_role}
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


apt update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt install -y kubelet kubeadm kubectl awscli
apt-mark hold kubelet kubeadm kubectl

apt-get install -y docker-ce

HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
hostnamectl set-hostname $HOSTNAME

if [ "$INSTANCE_ROLE" = "master" ]; then

cat <<EOF >config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
apiServer:
  extraArgs:
    cloud-provider: aws
clusterName: k8s-${cluster_name}-cluster
controlPlaneEndpoint: $HOSTNAME
controllerManager:
  extraArgs:
    cloud-provider: aws
    configure-cloud-routes: "false"
kubernetesVersion: stable
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  name: $HOSTNAME
  kubeletExtraArgs:
    cloud-provider: aws
EOF


    kubeadm init --config config.yaml
    
    CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
    echo $CERT_HASH >> /tmp/cert_hash
    echo $HOSTNAME >> /tmp/hostname

    echo $(kubeadm token create) > /tmp/join_token
    aws s3 cp /tmp/cert_hash  s3://${cluster_config_bucket}/config/
    aws s3 cp /tmp/join_token s3://${cluster_config_bucket}/config/join_token
    aws s3 cp /tmp/master_host_addr s3://${cluster_config_bucket}/config/master_host_addr

else

    aws s3 cp s3://${cluster_config_bucket}/config/cert_hash .
    aws s3 cp s3://${cluster_config_bucket}/config/join_token .
    aws s3 cp s3://${cluster_config_bucket}/config/master_host_addr .

    CERT_HASH=$(cat cert_hash)
    JOIN_TOKEN=$(cat join_token)
    MASTER_HOST_ADDR=$(cat master_host_addr)

    HOSTNAME=$(hostname)
    rm cert_hash
cat <<EOF >join.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $JOIN_TOKEN
    apiServerEndpoint: "$MASTER_HOST_ADDR:6443"
    caCertHashes:
      - "sha256:$CERT_HASH"
nodeRegistration:
  name: $HOSTNAME
  kubeletExtraArgs:
    cloud-provider: aws
EOF
    kubeadm join --config join.yaml

fi