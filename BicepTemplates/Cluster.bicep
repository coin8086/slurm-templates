param location string = resourceGroup().location
param adminUserName string
param adminUserSshPublicKey string
param headNodeVmSize string = 'Standard_D2alds_v6'
param headNodeName string = 'headnode'
param computeNodeVmSize string = 'Standard_D2alds_v6'
param computeNodeNamePrefix string = 'computenode-'
param computeNodeCount int
param computeNodeHasPublicIp bool = false

var subnetId = vnet.properties.subnets[0].id

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
        name: 'subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

module headNode 'HeadNode.bicep' = {
  name: 'headNodeDeployment'
  params: {
    location: location
    subnetId: subnetId
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
      subnetId: subnetId
      vmSize: computeNodeVmSize
      computerName: '${computeNodeNamePrefix}${i}'
      adminUserName: adminUserName
      adminUserSshPublicKey: adminUserSshPublicKey
      makePublicIp: computeNodeHasPublicIp
    }
  }
]

output publicIp string = headNode.outputs.publicIp
