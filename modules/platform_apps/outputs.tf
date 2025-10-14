# modules/platform_apps/outputs.tf

output "jenkins_url_instructions" {
  description = "Instrucciones para obtener la URL de Jenkins después del despliegue."
  value       = "Ejecuta 'kubectl get svc jenkins -n devops -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\"' y navega a http://<IP_RESULTANTE>:8080"
}

output "jenkins_admin_user" {
  description = "Usuario administrador de Jenkins"
  value       = var.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Contraseña del administrador de Jenkins"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "ingress_ip_instructions" {
  description = "Instrucciones para obtener la IP del Ingress Controller después del despliegue."
  value       = "Ejecuta 'kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\"'"
}
