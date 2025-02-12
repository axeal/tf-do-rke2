# Terraform config to launch Rancher 2 on an RKE2 cluster

## Summary

This Terraform setup will:

- Start `count_server_nodes` amount of droplets
- Create a loadbalancer pointing at the droplets for ports 80, 443, 6443 and 9345
- Install RKE2 on the first server node
- Install RKE2 on the other server nodes and join them to the first server node via the loadbalancer
- Install cert-manager
- Install the Rancher helm chart according to the version specified in `rancher_version` and the chart repository specified in `rancher_chart_repo` (default https://releases.rancher.com/server-charts/stable)

## Options

All available options/variables are described in [terraform.tfvars.example](https://github.com/axeal/tf-do-rke2/blob/master/terraform.tfvars.example).

## SSH Config

**Note: set the appropriate users for the images in the terraform variables, default is `root`**

You can use the use the auto-generated ssh_config file to connect to the droplets by droplet name, e.g. `ssh <prefix>-server-0`. To do so, you have two options:

1. Add an `Include` directive at the top of the SSH config file in your home directory (`~/.ssh/config`) to include the ssh_config file at the location you have checked out the this repository, e.g. `Include ~/git/tf-do-rke2/ssh_config`.

2. Specify the ssh_config file when invoking `ssh` via the `-F` option, e.g. `ssh -F ~/git/tf-do-rke2/ssh_config <host>`.

## How to use

- Clone this repository
- Move the file `terraform.tfvars.example` to `terraform.tfvars` and edit (see inline explanation)
- Run `terraform apply`