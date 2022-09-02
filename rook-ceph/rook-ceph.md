
# Install and setup Rook-Ceph cluster

```shell
# the manifests are provided but if want to use latest clone again, remember to change as per given manifests
# git clone --single-branch --branch master https://github.com/rook/rook.git
# cd rook/deploy/examples


cd deploy
kubectl create -f crds.yaml -f common.yaml -f operator.yaml


# create the pod security policy if enabled
kubectl create -f psp.yaml

#create the cluster

# alter the values in cluster-on-pvc.yaml
#  storageClassName: default # name of storage class tied to cinder
#      count: 2 # less than or equal to number of worker nodes
# size of storage pods, search for Gi
kubectl create -f cluster-on-pvc.yaml


#monitor creation
k get CephCluster -n rook-ceph
k describe cephcluster rook-ceph -n rook-ceph
k get pods -n rook-ceph



#get dashboard password
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
k port-forward service/rook-ceph-mgr-dashboard -n rook-ceph 8443:8443
# or apply the provided ingress


```
