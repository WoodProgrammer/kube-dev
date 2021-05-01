#!/bin/bash
set -e

deploy_vault(){

    helm install vault --wait \
        --set "server.dev.enabled=true"  \
        https://github.com/hashicorp/vault-helm/archive/v0.3.0.tar.gz
}

generate_password_nginx(){

    kubectl create ns monitoring
    htpasswd -c monitoring_passwd monitoring-user
    kubectl create secret generic monitoring_passwd --from-file=auth -n monitoring

    VALUE=$(cat monitoring_passwd)
    kubectl exec -it vault-0 -- sh -c "vault kv put internal/monitoring/passwd creds=${VALUE}"
    rm monitoring_passwd
    unset VALUE
}


deploy_monitoring_stack(){

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    kubectl create ns monitoring

    helm upgrade -i kube-prometheus -f monitoring/values.yaml --wait \
        -n monitoring \
        prometheus-community/kube-prometheus-stack

    kubectl apply -f monitoring/memory_rule.yaml
}


setup_nginx_ingress(){

    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    helm upgrade -i nginx-ingress --wait \
        --namespace=nginx-ingress --set nodeSelector="staging" --set controller.replicaCount=3 \
        ingress-nginx/ingress-nginx

}

setup_utils(){
    kubectl apply -f storage-class/gp2.yaml
    kubectl apply -f cni/calico/calico.yaml

}

deploy_vault
generate_password_nginx
deploy_monitoring_stack
setup_nginx_ingress
setup_storage_class