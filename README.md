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

To run the Ansible playbooks and Terraform configurations, you need to set the following environment variables:

### Proxmox

- `pm_user`: Proxmox user (e.g., `root`)
- `pm_password`: Proxmox password

### Ansible

- `ansible_ssh_key`: Path to the SSH private key file for Ansible (e.g., `~/.ssh/ansible_key`)

### Terraform

- `TF_VAR_pm_user`: Proxmox user (e.g., `root`)
- `TF_VAR_pm_password`: Proxmox password
- `TF_VAR_terraform_ssh_key`: Path to the SSH private key file for Terraform (e.g., `~/.ssh/terraform_key`)

### Example

Add the following lines to your `.bashrc` or `.zshrc` file, replacing with the actual details for your environment:

```sh
# Variables
# Proxmox
export pm_user="your_admin_user"
export pm_password="your_admin_password"

# Ansible
export ansible_ssh_key="path/to/ansible_key"

# Terraform
export TF_VAR_pm_user="$pm_user@pam"
export TF_VAR_pm_password=$pm_password
export TF_VAR_terraform_ssh_key="path/to/terraform_key"