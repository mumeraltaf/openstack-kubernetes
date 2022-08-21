k create ns cert-manager

#source https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml
# Updated:
# Deployment > name: cert-manager-webhook > template > spec > hostNetwork: true (ADDED)
# Deployment > name: cert-manager-webhook > template > spec > containers > args > --secure-port=10666 (updated from --secure-port=10250)
# Deployment > name: cert-manager-webhook > template > spec > containers > ports > containerPort=10666 (updated from containerPort=10250)
# Service > name: cert-manager-webhook > spec > ports > targetPort: 1066 (updated from "https")
k apply --validate=false  -f cert-manager.yaml

k create ns ingress-nginx

# source https://raw.githubusercontent.com/kubernetes/ingress-nginx/helm-chart-4.2.1/deploy/static/provider/cloud/deploy.yaml
#   updated: externalTrafficPolicy: Cluster
k -n ingress-nginx apply -f ingress-nginx.yaml


k -n ingress-nginx get svc

# wait for external-ip once done add DNS A record
k apply -f cert-issuer-nginx-ingress.yaml


# cd deployment

k apply -f service.yaml

# k port-forward svc/example-service 5000:80
 k apply -f certificate.yaml

