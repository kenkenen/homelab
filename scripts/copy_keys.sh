#!/bin/bash
# filepath: /home/kltej/devops/github/homelab/scripts/copy_keys.sh
# Variables
known_hosts_file="$HOME/.ssh/known_hosts"

# Function to create SSH key if it doesn't exist
create_ssh_key() {
  local key_path=$1
  local email=$2

  if [ ! -f "$key_path" ]; then
    echo "Creating SSH key: $key_path"
    ssh-keygen -t rsa -b 4096 -C "$email" -N "" -f "$key_path"
  else
    echo "SSH key already exists: $key_path"
  fi
}

# Function to clear host from known_hosts
clear_known_host() {
  local host=$1
  if ssh-keygen -F "$host" > /dev/null; then
    echo "Clearing $host from known_hosts"
    ssh-keygen -R "$host"
  fi
}

# Function to copy SSH key to remote host
copy_ssh_key() {
  local key_path=$1
  local host=$2
  local password=$3

  echo "Copying SSH key to $host"
  sshpass -p $password ssh-copy-id -o StrictHostKeyChecking=no -i "$key_path.pub" "$host" || echo "Failed to copy SSH key to $host"
}

# Load variables from YAML files using yq
hosts=$(envsubst < $HOME/devops/github/homelab/vars/hosts.yaml | yq -r '.hosts')
users=$(envsubst < $HOME/devops/github/homelab/vars/users.yaml | yq -r '.users')

for host in $(echo "$hosts" | jq -c '.[]'); do
  host_name=$(echo "$host" | jq -r '.name')
  host_ip=$(echo "$host" | jq -r '.ip')
  host_user=$(echo "$host" | jq -r '.user')
  host_password=$(echo "$host" | jq -r '.password')
  host_key_path=$(echo "$host" | jq -r '.key_path')

  clear_known_host "$host_ip"
done

for user in $(echo "$users" | jq -c '.[]'); do
  name=$(echo "$user" | jq -r '.name')
  key_path=$(echo "$user" | jq -r '.path')
  email=$(echo "$user" | jq -r '.email // empty')

  create_ssh_key "$key_path" "$email"

  for host in $(echo "$hosts" | jq -c '.[]'); do
    host_ip=$(echo "$host" | jq -r '.ip')
    host_user=$(echo "$host" | jq -r '.user')
    host_password=$(echo "$host" | jq -r '.password')

    copy_ssh_key "$key_path" "$host_user@$host_ip" "$host_password"
  done
done