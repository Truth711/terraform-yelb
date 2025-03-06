locals {
  registry_name = "registry"
}

resource "yandex_container_registry" "this" {
  name      = local.registry_name
  folder_id = var.folder_id
}

resource "yandex_vpc_security_group" "registry-sg" {
  description = "Security group for container registry"
  name        = "registry-sg"
  network_id  = yandex_vpc_network.this.id

  ingress {
    description    = "The rule allows connection to Yandex Container Registry on 5050 port"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5050
  }
}
