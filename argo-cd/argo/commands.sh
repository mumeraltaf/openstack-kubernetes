#https://argo-cd.readthedocs.io/en/stable/getting_started/

# create namespace and install argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# get password for the UI interface
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# port-forward to the ArgoCD UI Dashboard
kubectl port-forward svc/argocd-server -n argocd 8080:443
