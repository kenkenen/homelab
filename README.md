# homelab

This repository contains the configuration for a homelab setup using Proxmox as a VM host. The goal is to create a robust and flexible environment for deploying and managing various services commonly used in a home setting, such as OwnCloud, Plex, and more. The setup includes a CI/CD implementation for managing the deployment of these services.

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
export TF_VAR_pm_user=$pm_user
export TF_VAR_pm_password=$pm_password
export TF_VAR_terraform_ssh_key="path/to/terraform_key"
```

## Planned Designs

### CI/CD Implementation

The CI/CD pipeline will be used to manage the deployment of services to the homelab environment. The pipeline will include the following stages:

1. **Development**: Code and configuration changes are made and tested in a development environment.
2. **Staging**: Changes are deployed to a staging environment for further testing and validation.
3. **Production**: Once validated, changes are deployed to the production environment.

### Services

The following services are planned to be deployed and managed using the CI/CD pipeline:

- **OwnCloud**: A personal cloud storage solution for file sharing and synchronization.
- **Plex**: A media server for streaming movies, TV shows, music, and more.
- **Home Automation**: Solutions for automating various aspects of the home, such as lighting, security, and climate control.
- **Backup Solutions**: Services for backing up important data and ensuring data integrity.

### Infrastructure

The infrastructure will be managed using Proxmox as the VM host, with Ansible and Terraform used for provisioning and configuration management. The environment will be segmented into different networks for development, staging, and production to ensure isolation and manageability.