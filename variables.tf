variable "do_token" {
  default = "xxx"
}

variable "prefix" {
  default = "yourname"
}

variable "count_server_nodes" {
  default = "3"
}

variable "region" {
  default = "lon1"
}

variable "server_size" {
  default = "s-4vcpu-8gb"
}

variable "rke2_version" {
  default = ""
}

variable "image" {
  default = "ubuntu-22-04-x64"
}

variable "user" {
  default = "root"
}

variable "ssh_keys" {
  default = []
}

variable "rancher_chart_repo" {
  default = "https://releases.rancher.com/server-charts/stable"
}

variable "rancher_version" {
  default = "v2.10.2"
}

variable "admin_password" {
  default = "adminadminadmin"
}

