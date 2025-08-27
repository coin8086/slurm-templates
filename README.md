# Slurm Templates

The project provides ARM template files in Bicep to deploy a Slurm cluster on Azure. It can also setup a Slurm cluster on a set of computers, no matter they're virtual machines on Azure or some other cloud, or physical machines on premises.

The main template file is [Cluster.bicep](./BicepTemplates/Cluster.bicep). It creates a cluster of a single head node and zero or more compute nodes on Azure.

The Bash script [SetupCluster.sh](./Scripts/SetupCluster.sh) setups a Slurm cluster on a set of computers, which can be on any cloud or on premises.

See also [Install Slurm on Ubuntu 24.04](https://gist.github.com/coin8086/ea3d952025a3c8d8dda75210fb33a01e) for how to setup a Slurm cluster manually.
