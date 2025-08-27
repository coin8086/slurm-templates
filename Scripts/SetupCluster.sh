#!/bin/bash

# Execute this script on a host that has access to both the head node and compute nodes

# Parameters
# admin_user* The admin user on head node and compute nodes
# admin_user_ssh_private_key_file The SSH private key file path for the admin user
# slurm_user_db_passwd The database password for the slurm system user
# head_node The hostname of the head node
# compute_node_name_prefix The prefix for compute node hostnames. A compute node hostname is like "{prefix}{index}".
# compute_node_count* The number of compute nodes
# compute_node_cpus* The number of CPUs for a compute node

set -e

# Check if parallel-ssh and parallel-scp present
if ! type -t parallel-ssh parallel-scp >/dev/null; then
  echo "pssh is required but not installed."
  exit 1
fi

src_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
config_dir="$(dirname "$src_dir")/ConfigFiles"

admin_user=${admin_user:?'Environment variable "admin_user" must be set.'}
admin_user_ssh_private_key_file=${admin_user_ssh_private_key_file:-"$HOME/.ssh/id_rsa"}
slurm_user_db_passwd=${slurm_user_db_passwd:?'Environment variable "slurm_user_db_passwd" must be set.'}
head_node=${head_node:-'headnode'}
compute_node_name_prefix=${compute_node_name_prefix:-'computenode-'}
compute_node_count=${compute_node_count:?'Environment variable "compute_node_count" must be set.'}
compute_node_cpus=${compute_node_cpus:?'Environment variable "compute_node_cpus" must be set.'}

echo "## Add head node and compute nodes to SSH known hosts"

if ! ssh-keygen -F "$head_node" > /dev/null 2>&1; then
  ssh-keyscan -H "$head_node" >> ~/.ssh/known_hosts
fi

for (( i=1; i<=$compute_node_count; i++ )); do
  if ! ssh-keygen -F "computenode-$i" > /dev/null 2>&1; then
    ssh-keyscan -H "computenode-$i" >> ~/.ssh/known_hosts
  fi
done

echo "## Setup head node $head_node"

echo "### Uploading files to head node"
scp "$src_dir/SetupHeadNode.sh" "$src_dir/ConfigureMariaDB.sh" "$src_dir/ConfigureSlurmdbd.sh" "$src_dir/ConfigureSlurm.sh" "$src_dir/Test.sh" \
  "$config_dir/slurm.conf" "$config_dir/slurmdbd.conf" "$admin_user_ssh_private_key_file" \
  "$admin_user@$head_node":\~

private_key_file_name=$(basename "$admin_user_ssh_private_key_file")

echo "### Executing setup script on head node"
ssh "$admin_user@$head_node" <<EOF
export slurm_user_db_passwd=$slurm_user_db_passwd
export compute_node_name_prefix=$compute_node_name_prefix
export compute_node_count=$compute_node_count
export compute_node_cpus=$compute_node_cpus
bash ~/SetupHeadNode.sh

mv ~/$private_key_file_name ~/.ssh/
chmod 600 ~/.ssh/$private_key_file_name

sudo cp /etc/munge/munge.key ~
sudo chown $admin_user:$admin_user ~/munge.key
sudo chmod 600 ~/munge.key

sudo cp /etc/slurm/slurm.conf ~
sudo chown $admin_user:$admin_user ~/slurm.conf
sudo chmod 644 ~/slurm.conf
EOF

if (( $compute_node_count <= 0 )); then
  echo "## No compute node to setup"
  exit 0
fi

echo "## Setup $compute_node_count compute node(s)"

echo "### Downloading configuration files from head node"
scp "$admin_user@$head_node":\~/munge.key .
scp "$admin_user@$head_node":\~/slurm.conf .

host_file=./compute_nodes
if [[ -e $host_file ]]; then
  rm -f $host_file
fi

for (( i=1; i<=$compute_node_count; i++ )); do
  echo "$admin_user@computenode-$i" >> $host_file
done

echo "### Uploading files to compute nodes"
parallel-scp -h $host_file "$src_dir/SetupComputeNode.sh" ./munge.key ./slurm.conf \~

echo "### Executing setup script on compute nodes"
parallel-ssh -h $host_file 'bash ~/SetupComputeNode.sh'

echo "## Test on head node"
ssh "$admin_user@$head_node" <<EOF
sinfo
sbatch ~/Test.sh
scontrol show job
sacct
EOF

echo "Done"
