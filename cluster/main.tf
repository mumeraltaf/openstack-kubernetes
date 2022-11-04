terraform {
  required_version = ">= 1.3.0"

  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

locals {
  identity_service = [for entry in data.openstack_identity_auth_scope_v3.scope.service_catalog :
  entry if entry.type == "identity"][0]
  identity_endpoint = [for endpoint in local.identity_service.endpoints :
  endpoint if(endpoint.interface == "public" && endpoint.region == openstack_identity_application_credential_v3.rke2_csi.region)][0]

  os_cinder_b64 = base64gzip(templatefile("${path.root}/os_cinder.yaml.tpl", {
    auth_url   = local.identity_endpoint.url
    region     = local.identity_endpoint.region
    project_id = openstack_identity_application_credential_v3.rke2_csi.project_id
    app_id     = openstack_identity_application_credential_v3.rke2_csi.id
    app_secret = openstack_identity_application_credential_v3.rke2_csi.secret
  }))

  os_ccm_b64 = base64gzip(templatefile("${path.root}/os_ccm.yaml.tpl", {
    auth_url            = local.identity_endpoint.url
    region              = local.identity_endpoint.region
    project_id          = openstack_identity_application_credential_v3.rke2_csi.project_id
    app_id              = openstack_identity_application_credential_v3.rke2_csi.id
    app_secret          = openstack_identity_application_credential_v3.rke2_csi.secret
    floating_network_id = data.openstack_networking_network_v2.public_network.id
    subnet_id           = module.controlplane.subnet_id
  }))
}

data "openstack_identity_auth_scope_v3" "scope" {
  name = "auth_scope"
}

data "openstack_networking_subnet_v2" "nodes_subnet" {
  subnet_id = module.controlplane.subnet_id
}

data "openstack_networking_network_v2" "public_network" {
  # You MUST update this to match your cloud
  # do: `openstack subnet list`
  name = "melbourne"
}

resource "openstack_identity_application_credential_v3" "rke2_csi" {
  name = "${var.cluster_name}-csi-credentials"
}

resource "openstack_networking_secgroup_rule_v2" "nodeport" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32768
  remote_ip_prefix  = data.openstack_networking_subnet_v2.nodes_subnet.cidr
  security_group_id = module.controlplane.node_config.secgroup_id
}

module "controlplane" {
  source           = "remche/rke2/openstack"
  cluster_name     = var.cluster_name
  write_kubeconfig = true
  image_name       = "NeCTAR Ubuntu 22.04 LTS (Jammy) amd64"
  flavor_name      = "m3.large"
  public_net_name  = "melbourne"
  nodes_net_cidr  = "10.0.0.0/24"
  dns_servers = ["8.8.8.8", "8.8.4.4"]
#  dns_domain = "os-ccm.aurin-prod.cloud.edu.au."
  ssh_key_file     = "/Users/maalt/Desktop/adp-deploy-secrets/nectar/adp-terraform-key"
#  manifests_path   = "./manifests"
  boot_from_volume = true
  boot_volume_size = 100
  availability_zones = ["melbourne-qh2"]
  use_ssh_agent    = false
  nodes_count      = 1
  rke2_config      = file("rke2_config.yaml")
  manifests_gzb64 = {
    "cinder-csi-plugin" : local.os_cinder_b64
    "openstack-controller-manager" : local.os_ccm_b64
  }
}

module "worker" {
  source      = "remche/rke2/openstack//modules/agent"
  image_name  = "NeCTAR Ubuntu 22.04 LTS (Jammy) amd64"
  nodes_count = 3
  boot_from_volume = true
  boot_volume_size = 100
  name_prefix = "worker"
  flavor_name = "m3.large"
  node_config = module.controlplane.node_config
}

#resource "openstack_dns_recordset_v2" "domain" {
#  depends_on = [module.controlplane]
#  name    = format("*.%s.%s.",var.cluster_name,var.dns_base_url)
#  zone_id = var.dns_zone_id
#  ttl = 30
#  type = "A"
#  records = [module.controlplane.floating_ip.0]
#}