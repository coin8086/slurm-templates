#!/bin/bash

# Execute this script on a compute node

set -e

if [[ ! -e ./munge.key || ! -e ./slurm.conf ]]; then
  echo "Required files munge.key and/or slurm.conf are missing."
  exit 1
fi

sudo apt update

sudo apt install munge -y
sudo cp ./munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 600 /etc/munge/munge.key
sudo service munge restart

sudo apt install slurmd -y
sudo cp ./slurm.conf /etc/slurm/slurm.conf
sudo chown slurm:slurm /etc/slurm/slurm.conf
sudo chmod 644 /etc/slurm/slurm.conf
sudo service slurmd restart
