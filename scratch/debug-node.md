# SSH into any node 

```shell
# run a debug pod
kubectl run -i --rm --tty debug --image=debian --restart=Never -- sh

# install ssh-client
apt update
apt install openssh-client

# in different terminal copy over the private key for the cluster
kubectl cp /Users/maalt/Desktop/adp-deploy-secrets/nectar/adp-terraform-key debug:/keys

# back to debug terminal
ssh -i core@node-ip

# delete pod if for some reason disconnected
kubectl delete pod debug 
```

