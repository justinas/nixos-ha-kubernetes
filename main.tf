terraform {
  required_providers {
    libvirt = {
      source = "nixpkgs/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "k8s" {
  name      = "k8s"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["10.240.0.0/24"]

  dns {
    enabled = true
  }
}

resource "libvirt_volume" "nixos_boot" {
  name   = "boot"
  source = "boot/image/nixos.qcow2"
}

module "replicas" {
  for_each = {
    "etcd" : var.etcd_instances,
    "controlplane" : var.control_plane_instances,
  }

  source = "./replicas"

  name         = each.key
  num_replicas = each.value
  network_id   = libvirt_network.k8s.id
  volume_id    = libvirt_volume.nixos_boot.id
}

variable "etcd_instances" {
  type        = number
  description = "Amount of etcd hosts to spawn"
}

variable "control_plane_instances" {
  type        = number
  description = "Amount of control plane hosts to spawn"
}
