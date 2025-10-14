# modules/platform_apps/variables.tf

variable "jenkins_namespace" {
  description = "Namespace para desplegar Jenkins"
  type        = string
  default     = "tools"
}

variable "jenkins_admin_user" {
  description = "Usuario administrador de Jenkins"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Contraseña del administrador de Jenkins"
  type        = string
  sensitive   = true
}

variable "ingress_namespace" {
  description = "Namespace para el Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "namespace_dependency" {
  description = "Dependencia para asegurar que los namespaces existan antes de instalar los charts"
  type        = any
  default     = null
}