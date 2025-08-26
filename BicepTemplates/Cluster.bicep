param location string = resourceGroup().location
param adminUserName string
param adminUserSshPublicKey string
@secure()
param adminUserSshPrivateKey string
@secure()
param slurmUserDatabasePassword string
param headNodeVmSize string = 'Standard_D2alds_v6'
param headNodeName string = 'headnode'
param computeNodeVmSize string = 'Standard_D2alds_v6'
param computeNodeNamePrefix string = 'computenode-'
param computeNodeCount int
param computeNodeCpuCores int = 2 //This is for Standard_D2alds_v6
param computeNodeHasPublicIp bool = false

var defaultSubnetId = vnet.properties.subnets[0].id
var deploymentScriptsSubnetId = vnet.properties.subnets[1].id

//NOTE: A dedicated subnet with serviceEndpoints and delegations is required for deploymentScripts. For more, see
//https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#access-private-virtual-network
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: 'vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'deploymentScripts'
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints:[
            {
              service: 'Microsoft.Storage'
            }
          ]
          delegations: [
            {
              name: 'Microsoft.ContainerInstance.containerGroups'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

module headNode 'HeadNode.bicep' = {
  name: 'headNodeDeployment'
  params: {
    location: location
    subnetId: defaultSubnetId
    vmSize: headNodeVmSize
    computerName: headNodeName
    adminUserName: adminUserName
    adminUserSshPublicKey: adminUserSshPublicKey
  }
}

module computeNodes 'ComputeNode.bicep' = [
  for i in range(1, computeNodeCount): {
    name: 'computeNodeDeployment${i}'
    params: {
      location: location
      subnetId: defaultSubnetId
      vmSize: computeNodeVmSize
      computerName: '${computeNodeNamePrefix}${i}'
      adminUserName: adminUserName
      adminUserSshPublicKey: adminUserSshPublicKey
      makePublicIp: computeNodeHasPublicIp
    }
  }
]

module setupCluster 'SetupCluster.bicep' = {
  name: 'setupClusterDeployment'
  params: {
    location: location
    subnetId: deploymentScriptsSubnetId
    adminUserName: adminUserName
    adminUserSshPrivateKey: adminUserSshPrivateKey
    slurmUserDatabasePassword: slurmUserDatabasePassword
    headNodeName: headNodeName
    computeNodeNamePrefix: computeNodeNamePrefix
    computeNodeCount: computeNodeCount
    computeNodeCpuCores: computeNodeCpuCores
  }
  dependsOn: [
    headNode
    computeNodes
  ]
}

output publicIp string = headNode.outputs.publicIp
