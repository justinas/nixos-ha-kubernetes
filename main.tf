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

  xml {
    # By default, DHCP range is the whole subnet.
    # We will eventually want virtual IPs, so try to make space for them.
    # XSLT (I have no idea what I'm doing),
    # because of https://github.com/dmacvicar/terraform-provider-libvirt/issues/794
    xslt = <<EOF
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <xsl:template match="/network/ip/dhcp/range">
    <xsl:copy>
      <xsl:attribute name="start">10.240.0.100</xsl:attribute>
      <xsl:apply-templates select="@*[not(local-name()='start')]|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
EOF
  }
}

resource "libvirt_volume" "nixos_boot" {
  name   = "boot"
  source = "boot/image/nixos.qcow2"
}

module "replicas" {
  for_each = {
    "etcd" : {
      "count" : var.etcd_instances,
      "memory" : 512,
    }
    "controlplane" : {
      "count" : var.control_plane_instances,
      "memory" : 512,
    }
    "worker" : {
      "count" : var.worker_instances,
      "memory" : 1024,
    }
    "loadbalancer" : {
      "count" : var.load_balancer_instances,
      "memory" : 512,
    }
  }

  source = "./replicas"

  name         = each.key
  num_replicas = each.value.count
  memory       = each.value.memory
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

variable "worker_instances" {
  type        = number
  description = "Amount of worker hosts to spawn"
}

variable "load_balancer_instances" {
  type        = number
  description = "Amount of control plane load balancer hosts to spawn"
}
