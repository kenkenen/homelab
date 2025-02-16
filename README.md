# homelab

This repository contains the configuration for a homelab setup using Proxmox as a VM host. The goal is to create a robust and flexible environment for deploying and managing various services commonly used in a home setting, such as OwnCloud, Plex, and more. The setup includes a CI/CD implementation for managing the deployment of these containerized services onto Kubernetes.

## Getting Started

If you're trying to set up an identical set up as mine and have a laptop that can handle it, expand the Setting up Yyper-V section and follow it for a quick set up.

<details>
<summary>Setting up Hyper-V</summary>

If you have a laptop that can handle it, you can run the whole thing on Hyper-V on it. My 7th gen X1 carbon is dated and not a whole lot to rave about, but it handled the job well.

1. Enable Intel VT-x/VT-d in BIOS
2. Install Hyper-V by opening `appwiz.cpl`, clicking `Turn Windows features on or off` -> Check `Hyper-V` -> Follow prompts and reboot to complete the install.
3. Download [ProxMox ISO | https://enterprise.proxmox.com/iso/proxmox-ve_8.3-1.iso]
4. Execute the powershell script in the scripts folder
5. Run the `hyperv_init.ps1` powershell script

### Script Explanation:
The script first defines the names for the external and internal switches, retrieves the network adapter connected to the internet, and creates an external switch using that adapter. It then creates an internal switch for private networking. The script proceeds to define the VM's name, ISO file path, memory size, and disk size, creating a new VM with these specifications. Secure boot is disabled for the VM, and a virtual hard disk is added. Three network adapters are attached to the VM: two to the external switch and one to the internal switch, with MAC address spoofing enabled for all three. Finally, the ISO file is set as the DVD drive for the VM.

</details>

The first thing you'll want to do is deploy Proxmox VE onto some hardware. For the development of this repository, I used a virtual machine I created using Hyper-V on my Windows 11 laptop that meets the prereqs. The instructions on using Hyper-V for this set up are above.

## Environment Variables

You need to set the following environment variables. I set them in my bashrc so that it was loaded into the environment on start up. 

If you want to do the same, add the following lines to your `.bashrc` or `.zshrc` file, replacing with the actual details for your environment:

<details>
<summary>Environment variables.</summary>

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

### Initialization

I use Windows Subsystem Linux. You'll need `yq` for processing some data in the following script:

``` sh
chmod +x scripts/copy_keys.sh
./copy_keys.sh
```

This script will create ssh keys for the admin, ansible, and terraform users and copy them to the proxmox host.

### Ansible playbooks

Install Ansible

``` sh
sudo apt update && sudo apt install -y ansible
```

I have a series of playbooks that can be used to lay down the groundwork. 

With your variables declared and loaded into the environment, you can just execute these playbooks and have proxmox up and ready for vm and container deployment.

Execute the playbooks in the following order:

1. install_packages.yaml - Installs some packages needed on the Proxmox host.
2. update_host.yaml - Updates and cleans up packages.
3. create_storage.yaml - Creates storage on the Proxmox host.
4. dl_isos.yaml - Downloads a few isos used for the infrastructure deployment.
5. disable_firewall.yaml - Disables the firewall on the Proxmox host (we'll be using pfSense for that)
6. create_network.yaml - Creates the bridges needed for networking across infrastructure deployed to proxmox.

That's the basic initialization of the Proxmox host. It's now ready for VMs. Deploying VMs is better handled by terraform.

### Terraform Deployment of VMs

[Download Terraform | https://developer.hashicorp.com/terraform/install]

Extract it to your bin ($HOME/bin) or wherever makes sense for you. Also download and install the Terraform Proxmox Provider:

``` sh
mkdir -p ~/.terraform.d/plugins
wget -O ~/.terraform.d/plugins/terraform-provider-proxmox https://github.com/Telmate/terraform-provider-proxmox/releases/latest/download/terraform-provider-proxmox-linux-amd64
chmod +x ~/.terraform.d/plugins/terraform-provider-proxmox
```

In the proxmox_init folder, we have  a config file `main.tf` for the deployment of all of the VMs described in the variables file `terraform.tfvars`.

- pfSense VM - Handles firewall, routing, and DNS for the home network (if configured to do so) and all the VMs and Containers to be deployed in the DEV, UAT, and PROD environments.
- Lubuntu VM - A workstation connected to all the networks. Can be used for visibility from the inside.
- Ubuntu VM- Kubernetes host. I wanted a separate kubernetes environment instead of using Proxmox container platform.

Navigate to the folder and initiate terraform

``` sh
terraform init
```

Then execute the terraform plan and apply to deploy the listed VMs

``` sh
terraform plan
terraform apply
```

That's it! The VMs will be deployed and started, ready for configuration.

# TO DO

1. Need to set up playbook to create admin, user, guest, ansible, and terraform users on target host as required.
2. Set up the Cent OS host with k8s.