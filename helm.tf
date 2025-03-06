# nginx_ingress
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  depends_on = [null_resource.get_kube_credentials]
}

# cert_manager
resource "null_resource" "add_helm_repo" {
  provisioner "local-exec" {
    command = "helm repo add jetstack https://charts.jetstack.io && helm repo update"
  }
  depends_on = [null_resource.get_kube_credentials]
}

resource "helm_release" "cert_manager" {
  depends_on = [null_resource.add_helm_repo, null_resource.get_kube_credentials]

  name       = "cert-manager"
  chart      = "jetstack/cert-manager"
  version    = "v1.16.1"

  set {
    name  = "installCRDs"
    value = "true"
  }

  namespace = "cert-manager"
  create_namespace = true
}