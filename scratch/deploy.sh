kubectl apply -f backend-deployment.yaml

kubectl apply -f backend-service.yaml

kubectl apply -f frontend-deployment.yaml


kubectl apply -f frontend-service.yaml

#kubectl get service frontend --watch

#envsubst < externaldns.yaml | kubectl apply -f -

#kubectl config set-context --current --namespace=test