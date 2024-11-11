variable "cloudinit_template_name" {
    type = string 
}

variable "proxmox_node" {
    type = string
}

variable "ssh_key" {
    type = string
}

resource "proxmox_vm_qemu" "ubuntu" {
  count = 2
  vmid = "100${count.index + 1}"
  name = "ubuntu-0${count.index + 1}"
  target_node = var.proxmox_node
  clone = var.cloudinit_template_name
  agent = 1
  os_type = "cloud-init"
  cores = 1
  sockets = 1
  cpu = "host"
  memory = 1024
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    size = "50G"
    slot = "scsi0"
    storage = "ceph-pool-01"
  }

  disk {
    type     = "cloudinit"
    storage  = "ceph-pool-01"
    slot     = "ide0"
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.100.21${count.index + 1}/24,gw=192.168.100.1"
  nameserver = "1.1.1.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

