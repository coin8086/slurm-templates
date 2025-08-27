#!/bin/bash

# Parameters
# cluster_name
# head_node_name
# compute_node_name_prefix
# compute_node_count*
# compute_node_cpus*

set -e

cluster_name=${cluster_name:-'slurm-cluster-1'}
head_node_name=$(hostname)

compute_node_count=${compute_node_count:?'Environment variable "compute_node_count" must be set.'}

compute_node_name_prefix=${compute_node_name_prefix:-'computenode-'}
if (( $compute_node_count > 0 )); then
  compute_node_names=$compute_node_name_prefix\[1-$compute_node_count\]
  compute_node_cpus=${compute_node_cpus:?'Environment variable "compute_node_cpus" must be set.'}
  (( compute_node_cpus < 1)) && { echo "Invalid compute_node_cpus"; exit 1; }
else
  compute_node_names=''
  compute_node_cpus=0
fi

config=$(cat ./slurm.conf)
config=${config//\{ClusterName\}/$cluster_name}
config=${config//\{HeadNodeName\}/$head_node_name}
config=${config//\{NodeName\}/$compute_node_names}
config=${config//\{CPUs\}/$compute_node_cpus}
echo "$config" | sudo tee /etc/slurm/slurm.conf > /dev/null
sudo chown slurm:slurm /etc/slurm/slurm.conf
sudo chmod 644 /etc/slurm/slurm.conf
sudo service slurmctld restart
