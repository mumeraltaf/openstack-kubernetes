kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml
k apply -f rbac.yaml
k apply -f ingress.yaml
kubectl -n kubernetes-dashboard create token admin-user