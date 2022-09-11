## Display load balancer IP (typically present in GCP, or using Nginx ingress controller)
#output "load_balancer_ip" {
#  value = data.kubernetes_service_v1.load_balancer_nginx.status.0.load_balancer.0.ingress.0.ip
#}