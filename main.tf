# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_account" "do-account" {
}

resource "digitalocean_vpc" "droplets-network" {
  name   = "${var.prefix}-droplets-vpc"
  region = var.region
}

resource "time_sleep" "wait_20_seconds_to_destroy_vpc" {
  depends_on       = [digitalocean_vpc.droplets-network]
  destroy_duration = "20s"
}

resource "digitalocean_loadbalancer" "rke2-server" {
  depends_on            = [time_sleep.wait_20_seconds_to_destroy_vpc]
  name                  = "${var.prefix}-rke2-server"
  vpc_uuid              = digitalocean_vpc.droplets-network.id
  region                = var.region
  enable_proxy_protocol = true

  forwarding_rule {
    entry_port     = 6443
    entry_protocol = "tcp"

    target_port     = 6443
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port     = 9345
    entry_protocol = "tcp"

    target_port     = 9345
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "tcp"

    target_port     = 80
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "tcp"

    target_port     = 443
    target_protocol = "tcp"
  }

  healthcheck {
    port     = 9345
    protocol = "tcp"
  }

  droplet_tag = "${var.prefix}-rke2-server"

}

resource "random_string" "cluster-token" {
  length  = 24
  special = true
}

resource "digitalocean_droplet" "server-node" {
  depends_on = [time_sleep.wait_20_seconds_to_destroy_vpc]
  count      = var.count_server_nodes
  image      = var.image
  name       = "${var.prefix}-server-${count.index}"
  vpc_uuid   = digitalocean_vpc.droplets-network.id
  region     = var.region
  size       = var.server_size
  user_data = templatefile("files/userdata_server", {
    count              = "${count.index}"
    rke2_version       = var.rke2_version
    rancher_chart_repo = var.rancher_chart_repo
    rancher_version    = var.rancher_version
    admin_password     = var.admin_password
    token              = random_string.cluster-token.result
    lb_ip              = digitalocean_loadbalancer.rke2-server.ip
  })
  ssh_keys = var.ssh_keys
  tags = [
    join("", ["user:", replace(split("@", data.digitalocean_account.do-account.email)[0], ".", "-")]),
    "${var.prefix}-rke2-server"
  ]
}

resource "digitalocean_droplet" "agent-node" {
  depends_on = [time_sleep.wait_20_seconds_to_destroy_vpc]
  count      = var.count_agent_nodes
  image      = var.image
  name       = "${var.prefix}-agent-${count.index}"
  vpc_uuid   = digitalocean_vpc.droplets-network.id
  region     = var.region
  size       = var.agent_size
  user_data = templatefile("files/userdata_agent", {
    rke2_version = var.rke2_version
    token        = random_string.cluster-token.result
    lb_ip        = digitalocean_loadbalancer.rke2-server.ip
  })
  ssh_keys = var.ssh_keys
  tags = [
    join("", ["user:", replace(split("@", data.digitalocean_account.do-account.email)[0], ".", "-")])
  ]
}

resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/files/ssh_config_template", {
    prefix  = var.prefix
    servers = [for node in digitalocean_droplet.server-node : node.ipv4_address],
    agents  = [for node in digitalocean_droplet.agent-node : node.ipv4_address],
    user    = var.user
  })
  filename = "${path.module}/ssh_config"
}

output "rancher-url" {
  value = ["https://${digitalocean_loadbalancer.rke2-server.ip}.nip.io"]
}
output "Rancher_server-nodes-address" {
  description = "Rancher server nodes IP"
  value       = length(digitalocean_droplet.server-node[*].ipv4_address) > 0 ? digitalocean_droplet.server-node[*].ipv4_address : null
}
output "Rancher_agent-nodes-address" {                                                                                                                                                             
  description = "Rancher agent nodes IP"                                                                                                                                                           
  value       = length(digitalocean_droplet.agent-node[*].ipv4_address) > 0 ? digitalocean_droplet.agent-node[*].ipv4_address : null
}
