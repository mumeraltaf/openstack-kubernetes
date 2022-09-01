# Setup the OpenStack provider
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.48.0"
    }
  }
}

# Create the key pair for the entire cluster on OpenStack
resource "openstack_compute_keypair_v2" "kube_cluster_key" {
  name       = "kube_cluster_key"
  public_key = file(format("%s%s.pub", var.secrets_directory, var.ssh_key_file))
}

# Create a custom Cluster Template for our Kubernetes Cluster
resource "openstack_containerinfra_clustertemplate_v1" "umer_cluster_template" {
  cluster_distro        = "fedora-coreos"
  coe                   = "kubernetes"
  dns_nameserver        = "8.8.8.8"
  docker_storage_driver = "overlay2"
  docker_volume_size    = 100
  external_network_id   = "melbourne"
  flavor                = "c3.xxlarge"
  floating_ip_enabled   = true
  image                 = "fedora-coreos-35"
  master_flavor         = "m3.medium"
  master_lb_enabled     = true
  name                  = "umer_cluster_template"
  network_driver        = "flannel"
  no_proxy              = ""
  region                = "Melbourne"
  registry_enabled      = false
  server_type           = "vm"
  tls_disabled          = false
  volume_driver         = "cinder"

  labels = {
    autoscaler_tag                = "v1.23.0"
    availability_zone             = "melbourne-qh2"
    cinder_csi_enabled            = "true"
    cinder_csi_plugin_tag         = "v1.23.4"
    cloud_provider_tag            = "v1.23.4"
    container_infra_prefix        = "registry.rc.nectar.org.au/nectarmagnum/"
    container_runtime             = "containerd"
    containerd_tarball_sha256     = "a64568c8ce792dd73859ce5f336d5485fcbceab15dc3e06d5d1bc1c3353fa20f"
    containerd_version            = "1.6.6"
    coredns_tag                   = "1.9.3"
    csi_attacher_tag              = "v3.3.0"
    csi_node_driver_registrar_tag = "v2.4.0"
    csi_provisioner_tag           = "v3.0.0"
    csi_resizer_tag               = "v1.3.0"
    csi_snapshotter_tag           = "v4.2.1"
    docker_volume_type            = "standard"
    flannel_tag                   = "v0.18.1"
    ingress_controller            = "octavia"
    k8s_keystone_auth_tag         = "v1.23.4"
    kube_tag                      = "v1.23.8"
    master_lb_floating_ip_enabled = "true"
    influx_grafana_dashboard_enabled = "false"
    # the default full list as mentioned here https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/
    # admission_control_list = "CertificateApproval,CertificateSigning,CertificateSubjectRestriction,DefaultIngressClass,DefaultStorageClass,DefaultTolerationSeconds, LimitRanger, MutatingAdmissionWebhook, NamespaceLifecycle, PersistentVolumeClaimResize, PodSecurity, Priority,ResourceQuota,RuntimeClass,ServiceAccount,StorageObjectInUseProtection,TaintNodesByCondition,ValidatingAdmissionWebhook"
    # Removed PodSecurity from the default list, cert-manager was not able to work with it. More investigation needed here.
#    admission_control_list = "CertificateApproval,CertificateSigning,CertificateSubjectRestriction,DefaultIngressClass,DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,MutatingAdmissionWebhook,NamespaceLifecycle,PersistentVolumeClaimResize,Priority,ResourceQuota,RuntimeClass,ServiceAccount,StorageObjectInUseProtection,TaintNodesByCondition,ValidatingAdmissionWebhook"
  }
}

# Create the Kubernetes Cluster
resource "openstack_containerinfra_cluster_v1" "umer_cluster" {
  name                = "umer_cluster"
  cluster_template_id = openstack_containerinfra_clustertemplate_v1.umer_cluster_template.id
  master_count        = 1
  node_count          = 2
  keypair             = openstack_compute_keypair_v2.kube_cluster_key.name
}

# Export and save the KUBECONFIG file at the specified location
resource "local_sensitive_file" "config" {
  content  = tostring(openstack_containerinfra_cluster_v1.umer_cluster.kubeconfig.raw_config)
  filename = "${path.module}/secret/config"
}