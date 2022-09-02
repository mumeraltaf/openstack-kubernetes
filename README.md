# OpenStack Kubernetes based Developer Platform

A repo for showcasing a basic developer platform on an OpenStack Magnum Kubernetes Cluster, provisioned through [Terraform](https://www.terraform.io/).

## Current Features:
* Provision using Terraform from a custom Magnum Cluster Template
* Configure Persistent Storage Class for OpenStack
* Setup [cert-manager](https://cert-manager.io/) for X.509 certificate management using Terraform
* Setup internal [NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/) using Terraform, with auto provisioning cluster wide DNS hostname
* Optional setup of a [Rook](https://rook.io/) Ceph storage cluster, see [rook-ceph.md](rook-ceph/rook-ceph.md)
* [Argo CD](https://argo-cd.readthedocs.io/en/stable/) (continuous delivery) for the cluster (see `/argo-cd/argo/commands.sh` for installation instructions)
* Deploy an example app with valid SSL certificate using Terraform

## Prerequisites:
* Have appropriate OpenStack allocation (Clusters / Networks / FloatingIPs etc.), you can configure the resources used for cluster in the Cluster Template definition, here: [main.tf](./cluster/main.tf)
  * The supplied config needs following main resources:
    * 1 Cluster
    * 1 Network
    * 1 Router
    * 2 Floating IPs (one for cluster's main load-balancer, and one for NGINX Ingress Controller)
    * Appropriate compute and storage allocations as defined in the cluster template
* Be authenticated with OpenStack using Application/Personal credentials file
* Install [`Terraform`](https://www.terraform.io/)
* Install [`kubectl`](https://kubernetes.io/docs/tasks/tools/) (this may already be installed if you have Docker Desktop installed), I have an alias for it shortened to `k`
* Setup `secrets` directory with an already created/configured `ssh` key (password less), set or pass its path to `/cluster/variables.tf` file

# Magnum Cluster

The main terraform module creates a custom Magnum ClusterTemplate which is supported by the provider and configured to work with upcoming use-cases.
See [https://docs.openstack.org/magnum/latest/user/#clustertemplate](https://docs.openstack.org/magnum/latest/user/#clustertemplate) for details of all parameters and labels.

## Create a Kubernetes cluster
```shell
cd cluster
terraform init
terraform apply
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
cd cluster/configure
terraform init
terraform apply
```
After this complete a Volume will be provisioned and be available to be used by Kubernetes cluster.

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


### Use Kubernetes and Helm Terraform providers to setup addons

```shell
cd addons-terraform
terraform init
terraform apply
```

### (Optional) Manually setup cert-man using yaml manifests
See [Manually configure cert-man](./cert-manager-manual/Manual-cert-manager.md)


# Deploying workloads (applications) to the cluster
Following repo has an example application (Quarkus based API with PostgreSQL db), with the instructions to deploy to this kubernetes cluster: [Deploy Example App](https://github.com/mumeraltaf/quarkus-startmeup#deploy-application-on-remote-kubernetes-cluster).
