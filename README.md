# Cluster with Prometheus

* Cluster Provisioning
* Password Creds
* Monitoring Stack

## Cluster Provisioning
This cluster is provisioning via kubeadm and scripts are generating by terraform under module directory.
Storage class and Ingress requiremetns cloud-manager assigned as `AWS`.

`ami_id` added as constant to prevent possible changes of AMI ids by region (`ubuntu focal 20.04`)

## Password Creds

I've used `htpasswd` to provide credentials of basic http-authentication for monitoring stack;
you should set the values from your keyboard.

The `generate_password_nginx` function is uploading this secrets into Vault.

Storage class designed as encrpyted for Vault PVC's.

## Monitoring Stack
This stack is using prometheus-operator for monitoring purposes for memory alerts I've defined a `PrometheusRule` under monitoring directory.

```yaml
spec:
  groups:
  - name: container-memory-rules
    rules:
    - alert: ContainerMemoryUsage
      expr: (sum(container_memory_working_set_bytes) BY (name) / sum(container_spec_memory_limit_bytes > 0) BY (name) * 100) > 10
      labels:
        severity: warning
```
