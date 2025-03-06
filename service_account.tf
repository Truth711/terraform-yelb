resource "yandex_iam_service_account" "this" {
  description = "Service account to manage the Kubernetes cluster and node group"
  name        = "k8s-sa"
}

resource "yandex_iam_service_account_key" "this" {
  description        = "Authorized key for service account"
  service_account_id = yandex_iam_service_account.this.id
}

resource "local_sensitive_file" "key-json" {
  content = jsonencode({
    "id" : yandex_iam_service_account_key.this.id,
    "service_account_id" : yandex_iam_service_account_key.this.service_account_id,
    "created_at" : yandex_iam_service_account_key.this.created_at,
    "key_algorithm" : yandex_iam_service_account_key.this.key_algorithm,
    "public_key" : yandex_iam_service_account_key.this.public_key,
    "private_key" : yandex_iam_service_account_key.this.private_key
  })
  filename = "key.json"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.this.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  members = [
    "serviceAccount:${yandex_iam_service_account.this.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-pusher" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  members = [
    "serviceAccount:${yandex_iam_service_account.this.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "load-balancer-admin" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.this.id}"
  ]
}