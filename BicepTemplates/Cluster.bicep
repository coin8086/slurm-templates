param location string = resourceGroup().location
param adminUserName string
param adminUserSshPublicKey string
param computerNodeCount int

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
    adminUserName: adminUserName
    adminUserSshPublicKey: adminUserSshPublicKey
  }
}

module computeNodes 'ComputeNode.bicep' = [
  for i in range(1, computerNodeCount): {
    name: 'computeNodeDeployment${i}'
    params: {
      location: location
      subnetId: subnetId
      computerName: 'computenode-${i}'
      adminUserName: adminUserName
      adminUserSshPublicKey: adminUserSshPublicKey
    }
  }
]

output publicIp string = headNode.outputs.publicIp
