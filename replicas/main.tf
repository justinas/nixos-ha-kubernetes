# Spawns the given amount of machines,
# using the given base image as their root disk,
# attached to the same network.

terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

resource "libvirt_volume" "boot" {
  count = var.num_replicas

  name           = "${var.name}${count.index + 1}_boot"
  base_volume_id = var.volume_id
}

resource "libvirt_domain" "node" {
  count = var.num_replicas

  name = "${var.name}${count.index + 1}"

  memory = var.memory

  disk {
    volume_id = libvirt_volume.boot[count.index].id
  }

  network_interface {
    network_id     = var.network_id
    wait_for_lease = true
  }
}

