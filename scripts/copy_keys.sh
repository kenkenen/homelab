#!/bin/bash
# filepath: /home/kltej/devops/github/homelab/scripts/copy_keys.sh
# Variables
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

# Function to create SSH key if it doesn't exist
create_ssh_key() {
  local KEY_PATH=$1
  local EMAIL=$2

  if [ ! -f "$KEY_PATH" ]; then
    echo "Creating SSH key: $KEY_PATH"
    ssh-keygen -t rsa -b 4096 -C "$EMAIL" -N "" -f "$KEY_PATH"
  else
    echo "SSH key already exists: $KEY_PATH"
  fi
}

# Function to clear host from known_hosts
clear_known_host() {
  local HOST=$1
  if ssh-keygen -F "$HOST" > /dev/null; then
    echo "Clearing $HOST from known_hosts"
    ssh-keygen -R "$HOST"
  fi
}

# Function to copy SSH key to remote host
copy_ssh_key() {
  local KEY_PATH=$1
  local HOST=$2
  local PASSWORD=$3

  echo "Copying SSH key to $HOST"
  sshpass -p $PASSWORD ssh-copy-id -o StrictHostKeyChecking=no -i "$KEY_PATH.pub" "$HOST" || echo "Failed to copy SSH key to $HOST"
}

# Load variables from YAML files using yq
HOSTS=$(envsubst < $HOME/devops/github/homelab/vars/hosts.yaml | yq -r '.hosts')
USERS=$(envsubst < $HOME/devops/github/homelab/vars/users.yaml | yq -r '.users')

for HOST in $(echo "$HOSTS" | jq -c '.[]'); do
  HOST_IP=$(echo "$HOST" | jq -r '.ip')

  clear_known_host "$HOST_IP"
done

for USER in $(echo "$USERS" | jq -c '.[]'); do
  NAME=$(echo "$USER" | jq -r '.name')
  KEY_PATH=$(echo "$USER" | jq -r '.ssh_key_path')
  EMAIL=$(echo "$USER" | jq -r '.email // empty')

  create_ssh_key "$KEY_PATH" "$EMAIL"

  for HOST in $(echo "$HOSTS" | jq -c '.[]'); do
    HOST_IP=$(echo "$HOST" | jq -r '.ip')
    HOST_USER=$(echo "$HOST" | jq -r '.user')
    HOST_PASSWORD=$(echo "$HOST" | jq -r '.password')

    copy_ssh_key "$KEY_PATH" "$HOST_USER@$HOST_IP" "$HOST_PASSWORD"
  done
done