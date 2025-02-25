# homelab

This repository contains the configuration for a homelab setup using Proxmox as a VM host. The goal is to create structured infrastructure for deploying containerized applications into a DEV, UAT, and PROD environment. The infrastructure can be used for the implementation of pipelines to deploy developed containers to a DEV environment and progressively promote the deployments to the upper level environments using typical SDLC methodologies.

## Getting Started

If you're trying an identical set up as mine and have a laptop that can handle it, expand the Setting up Hyper-V section and follow it.

<details>
<summary>Setting up Hyper-V</summary>

My 7th gen X1 carbon is dated and not a whole lot to rave about, but it handled the job well. If you have a laptop with similar or better specs, then this might work for you as a quick and dirty development environment for this:

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

You need to set the following environment variables. I've loaded them all into an ansible vault and have a function in my bashrc to load them into the environment.

Bashrc function:
```sh
load_secrets() {
    VAULT_FILE="$HOME/devops/github/homelab/IaC/ansible/vault/secrets.yaml"
    VAULT_PASS_FILE="~/.ssh/id_rsa.pub"

    # Decrypt vault, parse variables, and suppress output
    while IFS=: read -r key value; do
        export "$(echo "$key" | xargs)"="$(echo "$value" | xargs)"
    done < <(ansible-vault view --vault-password-file "$VAULT_PASS_FILE" "$VAULT_FILE" | grep ': ')

    echo "Secrets loaded into env."
}
```

As you can see in the above snippit, I use my ssh public key as the password file. Feel free to use something more secure as this is only for development of this code and not for any kind of production environment.

Create the ansible vault:

```sh
ansible-vault create secrets.yaml
```

Expand the variables below and save them into the vault. Be sure to change values of the capitalized as these are placer values:

<details>
<summary>Environment variables.</summary>

```
## Local Env
DOWNLOADS_DIRECTORY: "PATH/TO/YOUR/DOWNLOADS ie /home/USER/downloads"
DOMAIN: "DOMAIN ie mydomain (not mydomain.com)"
NETWORK: "NETWORK/MASK ie. 192.168.1.0/24"

## Admin
ADMIN_EMAIL: 'ADMIN EMAIL'
ADMIN_USERNAME: 'ADMIN USERNAME'
ADMIN_PASSWORD: 'ADMIN PASSWORD'
ADMIN_SSH_KEY: "/PATH/TO/HOME/.ssh/id_rsa"

## Root
ROOT_PASSWORD: 'ROOT PASSWORD'

## Proxmox
PM_USER: "PROXMOX USER ie. root"
PM_PASSWORD: "PROXMOX USER PASSWORD"
PM_ADDRESS: "PROXMOX IP ADDRESS":

## Ansible
ANSIBLE_SSH_KEY: "/PATH/TO/HOME/.ssh/ansible_key"
```
</details>

### Initialization

I use Windows Subsystem Linux. You'll need `yq` for processing some data in the following script:

``` sh
sudo apt install -y yq
chmod +x scripts/copy_keys.sh
./copy_keys.sh
```

This script will create ssh keys for the admin and ansible users if they don't already exist and copy them to the proxmox host.

### Ansible playbooks

Install Ansible

``` sh
sudo apt install -y ansible
```

I have a series of playbooks that can be used to lay down the groundwork. With your variables declared and loaded into the environment, you can just execute these playbooks and have proxmox configured and running with a pfSense router and an Ubuntu server with k8s ready for your deployments.

Execute the playbooks in the following order:

1. update_host.yaml - Updates and cleans up packages.
2. create_storage.yaml - Creates storage on the Proxmox host.
3. download_media.yaml - Downloads a few isos used for the infrastructure deployment.
4. disable_firewall.yaml - Disables the firewall on the Proxmox host (we'll be using pfSense for hat)
5. create_network.yaml - Creates the bridges needed for networking across infrastructure deployed to proxmox.
6. create_confs.yaml - Loads the configuration files in the IaC/ansible/files/configs folder to an iso to be mounted on the VMs configured for it (pfSense)
7. create_cloudinit.yaml - Creates the cloud init configuration files for each k8s env
8. create_vms.yaml - Deploys the pfSense and k8s VMs with an unattended install of pfSense.

After a few minutes (about 25 minutes total) You should have a pfSense router accessible through https via the WAN address and three k8s nodes for a DEV, UAT, and PROD environment ready for deployments. For non-development use, you'll want to increase the resources allocated for the UAT and PROD VMs.

### Using the VMs

The pfSense router has 4 networks it services:

*LAN*: 192.168.1.0/24 - Used if you want pfSense to act as your router. Attach your home access point to the NIC being used so that pfSense handles DHCP/DNS. Devices on this network don't require routing to be specified.
*DEV*: 192.168.10.0/24
*UAT*: 192.168.20.0/24
*PROD*: 192.168.30.0/24

The WAN is configurd for DHCP, so you have to access the console to see what IP was assigned to it. With it, you can access the web configurator vie https.

Each of the k8s nodes should have an nginx deployment ready for connections via a random port between 30000-32767. If you access the console for each of them, you'll see the port you can access from the messages returned from the cloud-init configuration:

```
[  313.921776] cloud-init[1022]: nginx        NodePort    10.152.183.150   <none>        80:32334/TCP   3s
```

This specifies 32334 as the port to access. It won't be ready for connections for a few minutes. You can check if it is ready via the console:

```
devadmin@k8sdev:~$ sudo k8s kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE     IP           NODE     NOMINATED NODE   READINESS GATES
nginx-5869d7778c-7g62p   1/1     Running   0          3m57s   10.1.0.251   k8sdev   <none>           <none>
```

Anything other than `Running` means it is not ready.

### Setting a route to the networks

You'll need to set a route to these networks if you're not using the pfsense as your home router. In Windows 11, here's what you can do:

```sh
route -p add 192.168.10.0 MASK 255.255.255.0 x.x.x.x
```

Replace "x.x.x.x" with the WAN ip address of the pfsense router. Do the same for the other networks as well.

### Aftermath

That's it! This whole process should take around 25 minutes or so from when Proxmox is installed to being able to access the nginx server on the k8s node. Time to build some pipelines with ArgoCD and deploy away!
