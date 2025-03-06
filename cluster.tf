locals {
  k8s_cluster_name         = "k8s-cluster"
  k8s_node_group_name      = "k8s-node-group"
}

# Мастер
resource "yandex_kubernetes_cluster" "this" {
  description = "Managed Service for Kubernetes cluster"
  name        = local.k8s_cluster_name
  network_id  = yandex_vpc_network.this.id

  master {
    version = var.k8s_version
    master_location {
      zone      = var.master_location_zone
      subnet_id = yandex_vpc_subnet.this[var.master_location_zone].id
    }

    public_ip = true

    security_group_ids = [yandex_vpc_security_group.k8s-main-sg.id]
  }

  service_account_id      = yandex_iam_service_account.this.id
  node_service_account_id = yandex_iam_service_account.this.id
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.editor,
    yandex_resourcemanager_folder_iam_binding.images-puller,
    yandex_resourcemanager_folder_iam_binding.images-pusher
  ]
}

# Ноды
resource "yandex_kubernetes_node_group" "this" {
  description = "Node group for Managed Service for Kubernetes cluster"
  name        = local.k8s_node_group_name
  cluster_id  = yandex_kubernetes_cluster.this.id
  version     = var.k8s_version

  scale_policy {
    fixed_scale {
      size = var.number_of_nodes
    }
  }

  allocation_policy {
    dynamic "location" {
      for_each = var.az
      content {
        zone = location.value
      }
    }
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = [for s in yandex_vpc_subnet.this : s.id]
      security_group_ids = [
        yandex_vpc_security_group.k8s-main-sg.id,
        yandex_vpc_security_group.k8s-public-services.id,
      ]
    }

    resources {
      memory = var.node_memory
      cores  = var.node_cores
    }
    
    boot_disk {
      type = var.node_disk_type
      size = var.node_disk_size
    }
  }
}

# Секьюрити группы
resource "yandex_vpc_security_group" "k8s-main-sg" {
  description = "Security group ensure the basic performance of the cluster. Apply it to the cluster and node groups."
  name        = "k8s-main-sg"
  network_id  = yandex_vpc_network.this.id

  ingress {
    description    = "The rule allows availability checks from the load balancer's range of addresses. It is required for the operation of a fault-tolerant cluster and load balancer services."
    protocol       = "TCP"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    description       = "The rule allows the master-node and node-node interaction within the security group"
    protocol          = "ANY"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    description    = "The rule allows the pod-pod and service-service interaction. Specify the subnets of your cluster and services."
    protocol       = "ANY"
    v4_cidr_blocks = flatten(var.cidr_blocks)
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    description    = "The rule allows receipt of debugging ICMP packets from internal subnets"
    protocol       = "ICMP"
    v4_cidr_blocks = flatten(var.cidr_blocks)
  }

  ingress {
    description    = "The rule allows connection to Kubernetes API on 6443 port from specified network"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  ingress {
    description    = "The rule allows connection to Kubernetes API on 443 port from specified network"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  egress {
    description    = "The rule allows all outgoing traffic. Nodes can connect to Yandex Container Registry, Object Storage, Docker Hub, and more."
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "k8s-public-services" {
  description = "Security group allows connections to services from the internet. Apply the rules only for node groups."
  name        = "k8s-public-services-sg"
  network_id  = yandex_vpc_network.this.id

  ingress {
    description    = "The rule allows incoming traffic from the internet to the NodePort port range. Add ports or change existing ones to the required ports."
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }
}
