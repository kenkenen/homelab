# homelab

This repository contains the configuration for a homelab setup using Proxmox as a VM host. The goal is to create a robust and flexible environment for deploying and managing various services commonly used in a home setting, such as OwnCloud, Plex, and more. The setup includes a CI/CD implementation for managing the deployment of these containerized services onto Kubernetes.

## Getting Started

The first thing you'll want to do is deploy Proxmox VE onto some hardware. For the development of this repository, I used a virtual machine I created using Hyper-V on my Windows 11 laptop that meets the prereqs.

<details>
<summary>Expand for prereqs info</summary>

## Prerequisites for Running Proxmox as a VM

To run Proxmox VE as a virtual machine for development purposes, ensure that you meet the following prerequisites:

### Hardware Requirements

- **CPU**: Ensure that your host machine has a CPU that supports virtualization (e.g., Intel VT-x or AMD-V).
- **Memory**: Allocate sufficient RAM for both the host machine and the Proxmox VM. A minimum of 4GB for Proxmox is recommended, but more may be needed depending on your use case.
- **Storage**: Allocate enough disk space for the Proxmox VM and the VMs you plan to create within Proxmox.

### Virtualization Software

- **Hypervisor**: Use a hypervisor that supports nested virtualization, such as Hyper-V, VMware Workstation, or VirtualBox.
- **Nested Virtualization**: Ensure that nested virtualization is enabled in your hypervisor settings.

### Network Configuration

- **Bridged Networking**: Configure the Proxmox VM to use bridged networking to ensure it can communicate with other devices on your network.
- **Static IP**: Consider assigning a static IP address to the Proxmox VM for easier access and management.

### Proxmox VE ISO

- **Download**: Download the latest Proxmox VE ISO from the [official Proxmox website](https://www.proxmox.com/en/downloads).
- **Installation**: Follow the [Proxmox installation guide](https://pve.proxmox.com/wiki/Installation) to install Proxmox VE on the VM.

### Host Machine Configuration

- **Resources**: Ensure that the host machine has enough resources (CPU, RAM, and disk space) to run both the host OS and the Proxmox VM efficiently.
- **Virtualization Support**: Verify that virtualization support is enabled in the host machine's BIOS/UEFI settings.

</details>

## Environment Variables

You need to set the following environment variables. I set them in my bashrc so that it was loaded into the environment on start up. Add the following lines to your `.bashrc` or `.zshrc` file, replacing with the actual details for your environment:

<details>
<summary>You need to set the following environment variables.</summary>

## Env
export domain="DOMAIN"

## Admin
export admin_fname='ADMIN_FNAME'
export admin_lname='ADMIN_LNAME'
export admin_email='ADMIN_EMAIL'
export admin_username='ASMIN_USERNAME'
export admin_password='ADMIN_PASSWORD'
export admin_ssh_key="$HOME/.ssh/id_rsa"

## Root
export root_password='ROOT_PASSWORD'

## User
export user_fname="USER_FNAME"
export user_lname="USER_LNAME"
export user_email="USER_EMAIL"
export user_username="USER_USERNAME"
export user_password="USER_PASSWORD"

## Proxmox
export pm_user='root'
export pm_password="$root_password"
export pm_address="PROXMOX_IP"
export pm_netmask="PROXMOX_NETMASK"
export pm_gateway="PROXMOX_GATEWAY"
export pm_dns="PROXMOX_DNS"

## Ansible
export ansible_inv="$HOME/devops/github/homelab/IaC/ansible/inventory/hosts.ini"
export ansible_pbs="$HOME/devops/github/homelab/IaC/ansible/playbooks"
export ansible_ssh_key="$HOME/.ssh/ansible_key"
alias ansiblepb='ansible-playbook'
export ansible_username="ansible"
export ansible_password='ANSIBLE_PASSWORD'

## Terraform
export TF_VAR_pm_user="$pm_user@pam"
export TF_VAR_pm_password=$pm_password
export TF_VAR_terraform_ssh_key="$HOME/.ssh/terraform_key"
export TF_VAR_terraform_password='TERRAFORM_PASSWORD'
export TF_VAR_terraform_username="terraform"

</details>

Be sure to change values to fit your needs, especially the capitalized as these are placer values. Also, it's not recommended to store secrets in bashrc. In a future update, i'll be storing these in ansible vault and retrieving from there instead.

## Initialization

You'll need ```sh yq ``` for processing some data in the followin script:

``` sh
chmod +x scripts/copy_keys.sh
./copy_keys.sh
```

This script will copy ssh keys for the admin user, ansible, and terraform so that they can each ssh into the proxmox host as root.

## Ansible playbooks

I have a series of playbooks that can be used to lay down the groundwork. With your variables declared and loaded into the environment, you can just execute these playbooks and have the whole infrastructure up and ready for configuration.

Execute the playbooks in the following order:

1. install_packages.yaml - Installs some packages needed on the Proxmox host.
2. update_host.yaml - Updates and cleans up packages.
3. create_storage.yaml - Creates storage on the Proxmox host.
4. dl_isos.yaml - Downloads a few isos used for the infrastructure being deployed.
5. disable_firewall.yaml - Disables the firewall on the Proxmox host (we'll be using pfSense for that)
6. create_network.yaml - Creates the bridges needed for networking across the infrastructure.
7. create_vms.yaml - Creates the VMs for the infrastructure.

# TO DO

1. Add manual instructions or a powershell script for configuring Hyper-V
2. Need to create images for the disk a VM will use.
3. Need to create users on the proxmox host.