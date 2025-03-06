# Provider
variable "yandex_token" {
  type        = string
  description = "Token for Yandex Cloud"
}

variable "default_zone" {
  type = string
  default = "ru-central1-a"
  description = "Zone in which all cloud resources are created by default"
}

# Common
variable "cloud_id" {
  type        = string
  description = "ID of the Yandex Cloud"
}

variable "folder_id" {
  type        = string
  description = "ID of the Yandex Cloud folder"
}

# Network
variable "az" {
  type = list(string)
  default = [
    "ru-central1-a",
    "ru-central1-b",
  ]
  description = "Names of the Yandex.Cloud zone for subnet"
}

variable "network_name" {
  type = string
  default = "k8s-network"
  description = "The name of the network being created"
}

variable "cidr_blocks" {
  type        = list(list(string))
  description = "List of lists of IPv4 cidr blocks for subnets"
}

variable "labels" {
  type        = map(string)
  description = "Labels to add to resources"
}

# K8S cluster
variable "k8s_version" {
  type = string
  description = "Kubernetes version"
}

variable "master_location_zone" {
  type = string
  default = "ru-central1-a"
  description = "Zone in which master is located"
}

variable "number_of_nodes" {
  type = number
  description = "Kubernetes nodes number"
  default = 1
}

variable "node_memory" {
  description = "Объем памяти (в ГБ) для каждой ноды"
  type        = number
  default     = 4
}

variable "node_cores" {
  description = "Количество vCPU для каждой ноды"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Размер диска (в ГБ) для каждой ноды"
  type        = number
  default     = 32
}

variable "node_disk_type" {
  description = "Тип диска для каждой ноды"
  type        = string
  default     = "network-hdd"
}