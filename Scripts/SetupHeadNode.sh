#!/bin/bash

# Parameters
# slurm_user_db_passwd*
# compute_node_name_prefix
# compute_node_count*
# compute_node_cpus*

set -e

slurm_user_db_passwd=${slurm_user_db_passwd:?'Environment variable "slurm_user_db_passwd" must be set.'}
compute_node_name_prefix=${compute_node_name_prefix:-'computenode-'}
compute_node_count=${compute_node_count:?'Environment variable "compute_node_count" must be set.'}
compute_node_cpus=${compute_node_cpus:?'Environment variable "compute_node_cpus" must be set.'}

sudo apt-get update

sudo apt-get install munge -y

sudo apt-get install mariadb-server mariadb-client -y
slurm_user_db_passwd=$slurm_user_db_passwd ./ConfigureMariaDB.sh

sudo apt-get install slurmdbd -y
slurm_user_db_passwd=$slurm_user_db_passwd ./ConfigureSlurmdbd.sh

sudo apt-get install slurmctld -y
compute_node_name_prefix=$compute_node_name_prefix \
compute_node_count=$compute_node_count \
compute_node_cpus=$compute_node_cpus \
./ConfigureSlurm.sh
