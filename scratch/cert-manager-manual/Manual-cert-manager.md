# Manually setup cert-man using yaml manifests

Note: Certain modifications to the default Kubernetes yaml resources were needed to make things work on my OpenStack provider. These changes and source of original yaml files are also mentioned below:

* Install cert-manager using yaml file
```shell
cd cert-manager-manual
# source https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml
# Updated:
# Deployment name: cert-manager-webhook template spec hostNetwork: true (ADDED)
# Deployment name: cert-manager-webhook template spec containers args --secure-port=10666 (updated from --secure-port=10250)
# Deployment name: cert-manager-webhook template spec containers ports containerPort=10666 (updated from containerPort=10250)
# Service name: cert-manager-webhook spec ports targetPort: 1066 (updated from "https")
kubectl apply --validate=false  -f cert-manager.yaml
```
* Install Nginx Ingress Controller
```shell
kubectl create ns ingress-nginx
# source https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-4.2.1/deploy/static/provider/cloud/deploy.yaml
# Updated: 
# externalTrafficPolicy: Cluster
kubectl -n ingress-nginx apply -f ingress-nginx.yaml
```

* Check and wait for the Ingress controller to get an external IP assigned by the OpenStack Provider (takes about 2 mins)
```shell
kubectl -n ingress-nginx get svc
```

#### Register A record with OpenStack DNS provider (Designate) with required `HostName`
* `HostName` can be any valid hostname, example services given are configured for name like `umer-cluster2.aurin-prod.cloud.edu.au`. Update this name to what you want in following files:
    * `cert-manager-manual/deployment/certificate`
    * `cert-manager-manual/deployment/ingress`
* After status of Ingress External IP is updated from `Pending` to an actual IP address, add this address as an A record on the OpenStack DNS provider (Designate) with the required `HostName`. We may also be able to use Terraform to automate this step in future.

#### Get a LetsEncrypt certificate and start a `HelloWorld` example Service
* Now we can get `cert-manager` to request and manage the SSL certificate. The certificate will be named using a key and be saved in Kubernetes secret store. It will be renewed automatically by `cert-manager` before it expires.
```shell
cd cert-manager-manual/deployment
# Create the Kubernetes deployment for example app
kubectl apply -f deployment.yaml
# Create the Kubernetes service for example app
kubectl apply -f service.yaml
# Request and save the SSL Certificate to be used by our Ingress path
kubectl apply -f certificate.yaml
# Check status of the requested certificate, wait (upto 2-5 mins) and make sure the last status says `The certificate has been successfully issued`
kubectl describe certificate example-app
# Apply the Ingress path so the service is accessible from external internet
kubectl apply -f ingress.yaml
```
* Go to the `HostName` selected via a browser, if all went well you should be greeted by a Hello World! message and page should have valid X.509 certificate.
