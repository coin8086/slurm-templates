#!/bin/bash

# Parameters
# slurm_user_passwd*
# compute_node_name_prefix
# compute_node_count*
# compute_node_cpus*

set -e

slurm_user_passwd=${slurm_user_passwd:?'Environment variable "slurm_user_passwd" must be set.'}
compute_node_name_prefix=${compute_node_name_prefix:-'computenode-'}
compute_node_count=${compute_node_count:?'Environment variable "compute_node_count" must be set.'}
compute_node_cpus=${compute_node_cpus:?'Environment variable "compute_node_cpus" must be set.'}

sudo apt update

sudo apt install munge -y

sudo apt install mariadb-server mariadb-client -y
slurm_user_passwd=$slurm_user_passwd ./ConfigureMariaDB.sh

sudo apt install slurmdbd -y
slurm_user_passwd=$slurm_user_passwd ./ConfigureSlurmdbd.sh

sudo apt install slurmctld -y
compute_node_name_prefix=$compute_node_name_prefix \
compute_node_count=$compute_node_count \
compute_node_cpus=$compute_node_cpus \
./ConfigureSlurm.sh
