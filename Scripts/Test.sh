#!/bin/bash
#SBATCH --job-name=test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --output=test_%j.out
#SBATCH --error=test_%j.err

date -Is && hostname
echo "Working..."
sleep 30
date -Is
echo "Done"
