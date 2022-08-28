# OpenStack Kubernetes Cluster

A playpen repo for exploring OpenStack Magnum Kubernetes Cluster. I will keep adding features as I go along learning more stuff.

# Current Features:
* Provision using Terraform from a custom Magnum Cluster Template
* Provision Persistent Storage on OpenStack Volume
* Install [cert-manager](https://cert-manager.io/) for X.509 certificate management using Terraform or manually
* Install internal Nginx Ingress Controller using Terraform or manually
* Deploy an example `HelloWorld` app with valid SSL certificate using Terraform or manually
* [Argo CD](https://argo-cd.readthedocs.io/en/stable/) (continuous delivery) for the cluster (see `/argo-cd/argo/commands.sh` for installation instructions)
Prerequisites:
* Have appropriate OpenStack allocation (Clusters / Networks / FloatingIPs etc)
* Be authenticated with OpenStack using Application/Personal credentials file
* Install `Terraform`
* Install `kubectl` (this may already be installed if you have Docker Desktop installed), I have an alias for it shortened to `k`
* Setup `secrets` directory with an already created/configured `ssh` key, set or pass its path to `/cluster/variables.tf` file

# Magnum Cluster

The main terraform module creates a custom Magnum ClusterTemplate which is supported by the provider and configured to work with upcoming use-cases.
see [https://docs.openstack.org/magnum/latest/user/#clustertemplate](https://docs.openstack.org/magnum/latest/user/#clustertemplate) for details of all parameters and labels.

## Create a Kubernetes cluster
```shell
> cd cluster
> terraform init
> terraform apply
```
Wait for 5-15 minutes for cluster to be deployed

## Cluster KUBECONFIG

After the cluster is provisioned the `kubeconfig` file will be saved at `./cluster/secret/config`. Load this config into env variable:
```shell
> export KUBECONFIG=<PATH_TO_REPO>/cluster/secret/config
```

## Configure Cluster

After the cluster is created we will need to configure it for our use cases like:

* Set up the `cinder` `StorageClass` as default, for all `PersistentStorageClaims` in the cluster
* Install CRDs for utility packages like `cert-manger` and `argo-cd` or more.

To configure cluster, check/update the path to `kubeconfig` in the `./cluster/provision/variables.tf` file. Then:
```shell
> cd cluster/configure
> terraform init
> terraform apply
```
After this complete a Volume will be provisioned and be available to be used by Kubernetes cluster.

# Setup cert-manager
We will set up our cluster with [cert-manager](https://cert-manager.io/), which will automatically manage X.509 certificates in our cluster.

## Installation Methods
There are multiple ways to install [cert-manager](https://cert-manager.io/) into our cluster here are few options:
* Manual install using yaml files
* Use Helm charts for cert-manager and nginx-ingress installation
* Use Kubernetes and Helm Terraform providers to setup cert-manager


### Use Kubernetes and Helm Terraform providers to setup cert-manager and nginx-ingress-controller

```shell
> cd cert-manager-terraform
> terraform init
> terraform apply
```

### Manual install using yaml files

Note: Certain modifications to the default Kubernates yaml resources were needed to make things work on my OpenStack provider. These changes and source of original yaml files are also mentioned below:

* Install cert-manager using yaml file
```shell
> cd cert-manager-manual
# source https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml
# Updated:
# Deployment > name: cert-manager-webhook > template > spec > hostNetwork: true (ADDED)
# Deployment > name: cert-manager-webhook > template > spec > containers > args > --secure-port=10666 (updated from --secure-port=10250)
# Deployment > name: cert-manager-webhook > template > spec > containers > ports > containerPort=10666 (updated from containerPort=10250)
# Service > name: cert-manager-webhook > spec > ports > targetPort: 1066 (updated from "https")
> k apply --validate=false  -f cert-manager.yaml
```

* Install Nginx Ingress Controller 
```shell
> k create ns ingress-nginx
# source https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-4.2.1/deploy/static/provider/cloud/deploy.yaml
# Updated: 
# externalTrafficPolicy: Cluster
> k -n ingress-nginx apply -f ingress-nginx.yaml
```

* Check and wait for the Ingress controller to get an external IP assigned by the OpenStack Provider (takes about 2 mins)
```shell
> k -n ingress-nginx get svc
```

#### Register A record with OpenStack DNS provider (Designate) with required `HostName`
* `HostName` can be any valid hostname, example services given are configured for name like `umer-cluster2.aurin-prod.cloud.edu.au`. Update this name to what you want in following files:
  * `cert-manager-manual/deployment/certificate`
  * `cert-manager-manual/deployment/ingress`
* After status of Ingress External IP is updated from `Pending` to an actual IP address, add this address as an A record on the OpenStack DNS provider (Designate) with the required `HostName`. We may also be able to use Terraform to automate this step in future.

#### Get a LetsEncrypt certificate and start a `HelloWorld` example Service
* Now we can get `cert-manager` to request and manage the SSL certificate. The certificate will be named using a key and be saved in Kubernetes secret store. It will be renewed automatically by `cert-manager` before it expires.
```shell
> cd cert-manager-manual/deployment
# Create the Kubernetes deployment for example app
> k apply -f deployment.yaml
# Create the Kubernetes service for example app
> k apply -f service.yaml
# Request and save the SSL Certificate to be used by our Ingress path
> k apply -f certificate.yaml
# Check status of the requested certificate, wait (upto 2-5 mins) and make sure the last status says `The certificate has been successfully issued`
> k describe certificate example-app
# Apply the Ingress path so the service is accessible from external internet
> k apply -f ingress.yaml
```
* Go to the `HostName` selected via a browser, if all went well you should be greeted by a Hello World! message and page should have valid X.509 certificate.
