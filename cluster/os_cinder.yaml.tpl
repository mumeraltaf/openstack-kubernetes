apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cinder-csi-plugin
  namespace: kube-system
spec:
  chart: openstack-cinder-csi
  repo: https://kubernetes.github.io/cloud-provider-openstack
  version: 2.1.0
  targetNamespace: kube-system
  bootstrap: True
  valuesContent: |-
    secret:
     enabled: true
     create: true
     name: cinder-csi-cloud-config
     filename: cloud.conf
     data:
       cloud-config: |-
         [Global]
         auth-url=${auth_url}
         application-credential-id=${app_id}
         application-credential-secret=${app_secret}
         region=${region}
         tenant-id=${project_id}
