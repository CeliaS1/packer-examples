packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "iso_location" {
  type    = string
  default = "http://mirrors.ircam.fr/pub/CentOS/7/isos/x86_64/CentOS-7-x86_64-Minimal-2207-02.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:d68f92f41ab008f94bd89ec4e2403920538c19a7b35b731e770ce24d66be129a"
}

variable "user" {
  type    = string
  default = "packer"
}

variable "password" {
  type      = string
  default   = "packer"
  sensitive = true
}

variable "message" {
  type    = string
  default = "CentOS Image Builder for Virtualbox"
}

source "virtualbox-iso" "centos7-basic" {
  guest_os_type    = "RedHat_64"
  iso_url          = var.iso_location
  iso_checksum     = var.iso_checksum
  ssh_username     = var.user
  ssh_password     = var.password
  shutdown_command = "echo '${var.password}' | sudo -S shutdown -P now"
  nested_virt      = false
  ssh_wait_timeout = "9000s"
  disk_size        = 10000
  boot_wait        = "10s"
  http_content = {
    "/ks.cfg" = file("http/ks.cfg")
  }
  boot_command = [
    "<tab><wait>",
    " ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"
  ]
}

build {
  sources = ["sources.virtualbox-iso.centos7-basic"]

  provisioner "ansible" {
    playbook_file       = "./ansible/playbook.yml"
    extra_arguments     = ["--extra-vars", "packer_message=${var.message} ansible_user=${var.user} ansible_password=${var.password} ansible_become_password=${var.password}"]
    keep_inventory_file = true
    use_proxy           = false
    ansible_env_vars    = ["ANSIBLE_HOST_KEY_CHECKING=false"]
  }
}
