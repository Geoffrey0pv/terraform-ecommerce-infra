# Jenkins Helm Chart
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = var.jenkins_namespace
  version    = "4.3.20" # Versión estable

  values = [
    file("${path.root}/helm/charts/jenkins/values.yaml")
  ]

  set {
    name  = "controller.admin.password"
    value = var.jenkins_admin_password
  }

  # Depende de que el namespace exista
  depends_on = [var.namespace_dependency]
}

# NGINX Ingress Controller Helm Chart
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = var.ingress_namespace
  version    = "4.7.1"

  values = [
    file("${path.root}/helm/charts/ingress-nginx/values.yaml")
  ]

  depends_on = [var.namespace_dependency]
}

data "kubernetes_service" "jenkins_service" {
  metadata {
    name      = helm_release.jenkins.name
    namespace = helm_release.jenkins.namespace
  }
  depends_on = [helm_release.jenkins]
}

data "kubernetes_service" "nginx_ingress_service" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = var.ingress_namespace
  }
  depends_on = [helm_release.nginx_ingress]
}