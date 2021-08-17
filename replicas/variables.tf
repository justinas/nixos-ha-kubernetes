variable "name" {
  type        = string
  description = "Base name for the machine and boot volume"
}

variable "num_replicas" {
  type        = number
  description = "Amount of machines to spawn"
}

variable "network_id" {
  type        = string
  description = "Libvirt network to attach the machines to"
}

variable "volume_id" {
  type        = string
  description = "ID of the volume to base the boot drive on"
}
