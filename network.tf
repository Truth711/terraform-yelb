resource "yandex_vpc_network" "this" {
  description = "Network for the Managed Service for Kubernetes cluster"
  name        = var.network_name
  labels      = var.labels
}

resource "yandex_vpc_subnet" "this" {
  for_each = toset(var.az)

  description    = "Subnet in ${each.value} availability zone"
  name           = each.value
  zone           = each.value
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = var.cidr_blocks[index(var.az, each.value)]
  labels         = var.labels
}

resource "yandex_dns_zone" "zone1" {
  name        = "zone1"
  description = "ДНС зона 1"

  labels = var.labels

  zone    = "s060709.online."
  public  = true
}
