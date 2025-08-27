#! /bin/bash

# NOTE:
# The DeploymentScripts container is of Azure Linux 3.0 with tdnf. Try a container of mcr.microsoft.com/azure-cli:2.75.0 for it.
# For more about the DeploymentScripts container see
# https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template-configure-dev#use-docker

set -e
shopt -s expand_aliases

: ${admin_user:?'Environment variable "admin_user" must be set.'}
: ${admin_user_ssh_private_key:?'Environment variable "admin_user_ssh_private_key" must be set.'}
: ${slurm_user_db_passwd:?'Environment variable "slurm_user_db_passwd" must be set.'}
: ${head_node:?'Environment variable "head_node" must be set.'}
: ${compute_node_name_prefix:?'Environment variable "compute_node_name_prefix" must be set.'}
: ${compute_node_count:?'Environment variable "compute_node_count" must be set.'}
: ${compute_node_cpus:?'Environment variable "compute_node_cpus" must be set.'}

# NOTE
# The container is in a different subnet from the one of the head and compute nodes. According to the following Azure documents
# https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#access-private-virtual-network
# https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances?tabs=redhat#azure-provided-name-resolution
# the container should be able to resolve the node names. However, there seems an issue in Azure about the name resolution.
# So here /etc/resolv.conf is modified to resolve the issue.

echo "## Configure /etc/resolv.conf"

if ! grep -q '^search .*\<internal.cloudapp.net\>' /etc/resolv.conf; then
  # NOTE: "sed -i" causes error in the container environment.
  conf=$(sed 's/^search /search internal.cloudapp.net /' /etc/resolv.conf)
  echo "$conf" > /etc/resolv.conf
fi

echo "## Install required tools"

tdnf install wget tar openssh pssh -y
alias parallel-ssh=pssh
alias parallel-scp=pscp.pssh

echo "## Create SSH private key file"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

export admin_user_ssh_private_key_file=$HOME/.ssh/id_rsa
echo -n "$admin_user_ssh_private_key" > "$admin_user_ssh_private_key_file"
chmod 600 "$admin_user_ssh_private_key_file"

echo "## Download package of slurm-templates"

package_dir=./slurm-templates
if [[ -e $package_dir ]]; then
  rm -rf "$package_dir"
fi
mkdir -p "$package_dir"

package_url=https://github.com/coin8086/slurm-templates/archive/refs/tags/v1.0.0-beta2.tar.gz
wget -qO- "$package_url" | tar xz --strip 1 -C "$package_dir"
chmod -R +x "$package_dir/Scripts/"

echo "## Start setup"
# NOTE: The script is sourced, otherwise the aliases set previously will not be available in the script.
# Also note that "shopt -s expand_aliases" must be set to make aliases available in the current script.
. "$package_dir/Scripts/SetupCluster.sh"
