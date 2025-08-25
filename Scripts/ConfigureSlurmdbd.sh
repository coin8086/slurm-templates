#!/usr/bin/env bash

# Parameters
# slurm_user_passwd*

set -e

slurm_user_passwd=${slurm_user_passwd:?'Environment variable "slurm_user_passwd" must be set.'}

config=$(cat ./slurmdbd.conf)
config=${config//\{StoragePass\}/$slurm_user_passwd}
echo "$config" | sudo tee /etc/slurm/slurmdbd.conf > /dev/null
sudo chown slurm:slurm /etc/slurm/slurmdbd.conf
sudo chmod 600 /etc/slurm/slurmdbd.conf
sudo service slurmdbd restart
