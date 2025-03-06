#.kube/config update (local)
resource "null_resource" "get_kube_credentials" {
  depends_on = [yandex_kubernetes_cluster.this]
  
  provisioner "local-exec" {
    command = "yc managed-kubernetes cluster get-credentials k8s-cluster --external --force"
    interpreter = ["PowerShell", "-Command"]
  }

}

# Image Pull Secret
resource "kubernetes_secret" "yc_registry_secret" {
  depends_on = [null_resource.get_kube_credentials, yandex_kubernetes_cluster.this]

  metadata {
    name      = "yc-registry-secret"
    namespace = "default"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "cr.yandex" = {
          "username" = "oauth"
          "password" = var.yandex_token
          "auth"     = base64encode("oauth:${var.yandex_token}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Service Account
resource "kubernetes_service_account" "cicd_sa" {
  depends_on = [null_resource.get_kube_credentials, yandex_kubernetes_cluster.this]
  metadata {
    name      = "cicd"
    namespace = "default"
  
    labels = {
        "app.kubernetes.io/managed-by" = "Helm"
      }

    annotations = {
      "meta.helm.sh/release-namespace" = "default"
    }
  }
  
  automount_service_account_token = true

  image_pull_secret {
    name = kubernetes_secret.yc_registry_secret.metadata[0].name
  }
}

# Token for SA
resource "kubernetes_secret" "cicd_sa_token" {
  depends_on = [kubernetes_service_account.cicd_sa]

  metadata {
    name      = "cicd-sa-token"
    namespace = "default"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.cicd_sa.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

# Cluster Role for SA
resource "kubernetes_cluster_role" "continuous_deployment_role" {
  depends_on = [kubernetes_service_account.cicd_sa]

  metadata {
    name = "continuous-deployment"
  }

  rule {
    api_groups = [
      "",
      "apps",
      "networking.k8s.io",
      "cert-manager.io"
    ]
    resources = [
      "namespaces",
      "deployments",
      "replicasets",
      "ingresses",
      "services",
      "secrets",
      "serviceaccounts",
      "configmaps",
      "persistentvolumeclaims",
      "clusterissuers"
    ]
    verbs = [
      "create",
      "delete",
      "deletecollection",
      "get",
      "list",
      "patch",
      "update",
      "watch"
    ]
  }
}

# Cluster Role Binding for SA
resource "kubernetes_cluster_role_binding" "cicd_role_binding" {
  depends_on = [kubernetes_service_account.cicd_sa, kubernetes_cluster_role.continuous_deployment_role]

  metadata {
    name = "cicd-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cicd_sa.metadata[0].name
    namespace = kubernetes_service_account.cicd_sa.metadata[0].namespace
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.continuous_deployment_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
