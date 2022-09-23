# RKE2 based Developer Platform on OpenStack provisioned using Terraform

A repo for showcasing a basic developer platform on an RKE2 based Kubernetes Cluster on OpenStack, provisioned through [Terraform](https://www.terraform.io/).

The cluster is provisioned using following Terraform modules:
[terraform-openstack-rke2](https://github.com/remche/terraform-openstack-rke2)

## Current Features:
* Provision RKE2 Cluster on OpenStack using Terraform
* Setup a GitOps enabled fleet GitHub repository for all cluster configurations
* Install and configure [OpenStack Cloud Controller Manager](https://github.com/kubernetes/cloud-provider-openstack)
* Install and configure [Cinder CSI Plugin](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/cinder-csi-plugin/using-cinder-csi-plugin.md)
* Configure Persistent Storage Class for OpenStack
* Setup [cert-manager](https://cert-manager.io/) for X.509 certificate management using Terraform
* Setup internal [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/) using Terraform, with auto provisioning cluster wide DNS hostname
* Optional setup of a [Rook](https://rook.io/) Ceph storage cluster, see [rook-ceph.md](rook-ceph/rook-ceph.md)
* [Actions Runner Controller (ARC)](https://github.com/actions-runner-controller/actions-runner-controller) for self-hosted GitHub workflow runners, providing an internal CI and code build platform
* [Argo CD](https://argo-cd.readthedocs.io/en/stable/) (continuous delivery) for the cluster (see `/argo-cd/argo/commands.sh` for installation instructions)
* Deploy an example app with valid SSL certificate using Terraform

## Prerequisites:
* Have appropriate OpenStack allocation ( Networks / FloatingIPs etc.), you can configure the resources used for cluster in the Cluster Template definition, here: [main.tf](./cluster/main.tf)
  * The supplied config needs following main resources:
    * 1 Network
    * 1 Router
    * 1 Floating IP
    * Appropriate compute and storage allocations as defined in the cluster template
* Be authenticated with OpenStack using Application/Personal credentials file
* Install [`Terraform`](https://www.terraform.io/)
* Install [`kubectl`](https://kubernetes.io/docs/tasks/tools/) (this may already be installed if you have Docker Desktop installed), I have an alias for it shortened to `k`
* Setup `secrets` directory with an already created/configured `ssh` key (password less), set or pass its path to `/cluster/variables.tf` file

# RKE2 Cluster

The main terraform module creates a RKE2 Cluster using follwoing Terraform Module: [terraform-openstack-rke2](https://github.com/remche/terraform-openstack-rke2).

To make it work well in OpenStack we install following plugins and controller.

* [OpenStack Cloud Controller Manager](https://github.com/kubernetes/cloud-provider-openstack): This will allow us to provision LoadBalancers on OpenStack directly from Kubernetes Services
* [Cinder CSI Plugin](https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/cinder-csi-plugin/using-cinder-csi-plugin.md): This will enable the cluster to use Cinder Storage 
## Create a Kubernetes cluster
```shell
cd cluster
terraform init
terraform apply -var-file="/Users/maalt/Desktop/k8_secrets/secrets.tfvars"
```
Wait for 5-15 minutes for cluster to be deployed

### Cluster KUBECONFIG

After the cluster is provisioned the `kubeconfig` file will be saved at `./cluster/secret/config`. Load this config into env variable:
```shell
export KUBECONFIG=<PATH_TO_REPO>/cluster/secret/config
```

### Configure Cluster

After the cluster is created we will need to configure it for our use cases like:

* Set up the `cinder` `StorageClass` as default, for all `PersistentStorageClaims` in the cluster
* Install CRDs for utility packages like `cert-manger` and `argo-cd` or more.

To configure cluster, check/update the path to `kubeconfig` in the `./cluster/provision/variables.tf` file. Then:
```shell
cd cluster/flux-bootstrap
terraform init
terraform apply -var-file="/Users/maalt/Desktop/k8_secrets/fluxSecrets.tfvars" 
```
After this complete a StorageClass named `default` will be setup and be available to be used by Kubernetes cluster.



To init cluster, check/update the path to `kubeconfig` in the `./cluster/provision/variables.tf` file. Then:
```shell
cd cluster/flux-bootstrap/configure
terraform init
terraform apply -var-file="/Users/maalt/Desktop/k8_secrets/fluxSecrets.tfvars" 
```


To init cluster, check/update the path to `kubeconfig` in the `./cluster/provision/variables.tf` file. Then:
```shell
cd cluster/flux-bootstrap/configure/init-platform
terraform init
terraform apply -var-file="/Users/maalt/Desktop/k8_secrets/fluxSecrets.tfvars" 
```



# Setup Cluster Addons
Now that we have a working cluster setup, we can install and configure some essential cluster addons. Following addons will be installed:
* [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/), will be default Ingress Controller for our cluster, a DNS hostname for whole cluster will be provisioned from OpenStack using `designate` API, configure this in [variables.tf](addons-terraform/variables.tf)
* [cert-manager](https://cert-manager.io/docs/), will automatically manage X.509 certificates in our cluster.
* [Argo CD](https://argo-cd.readthedocs.io/en/stable/), will be setup to enable continuous deployment of user workloads

## Installation Methods
There are multiple ways to install packages into our cluster here are few options:
* Manual install using yaml files
* Use Helm charts
* Use Kubernetes and Helm Terraform providers to setup packages


### Use Kubernetes + Helm Terraform providers to setup addons

```shell
cd addons-terraform
terraform init
terraform apply -var-file="/Users/maalt/Desktop/k8_secrets/secrets.tfvars"
```

### (Optional) Manually setup cert-man using yaml manifests
See [Manually configure cert-man](./scratch/cert-manager-manual/Manual-cert-manager.md)


# Deploying workloads (applications) to the cluster
Following repo has an example application (Quarkus based API with PostgreSQL db), with the instructions to deploy to this kubernetes cluster: [Deploy Example App](https://github.com/mumeraltaf/quarkus-startmeup#deploy-application-on-remote-kubernetes-cluster).
