param location string = resourceGroup().location
param now string = utcNow()
param subnetId string
param adminUserName string
@secure()
param adminUserSshPrivateKey string
@secure()
param slurmUserDatabasePassword string
param headNodeName string = 'headnode'
param computeNodeNamePrefix string = 'computenode-'
param computeNodeCount int
param computeNodeCpuCores int

var storageAccountName = substring('setup${uniqueString(resourceGroup().id, 'setup')}', 0, 18)
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetId
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
      defaultAction: 'Deny'
    }
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'setupIdentity'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.id, 'Contributor')
  scope: storageAccount
  properties: {
    principalType: 'ServicePrincipal'
    principalId: identity.properties.principalId
    //Storage File Data Privileged Contributor
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '69566ab7-960f-475b-8e7c-b3118f30c6bd')
  }
}

resource setup 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'setupCluster'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.75.0'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT2H'
    forceUpdateTag: guid(now)
    storageAccountSettings: {
      storageAccountName: storageAccount.name
    }
    containerSettings: {
      subnetIds:[
        {
          id: subnetId
        }
      ]
    }
    environmentVariables:[
      {
        name: 'admin_user'
        value: adminUserName
      }
      {
        name: 'admin_user_ssh_private_key'
        secureValue: adminUserSshPrivateKey
      }
      {
        name: 'slurm_user_db_passwd'
        secureValue: slurmUserDatabasePassword
      }
      {
        name: 'head_node'
        value: headNodeName
      }
      {
        name: 'compute_node_name_prefix'
        value: computeNodeNamePrefix
      }
      {
        name: 'compute_node_count'
        value: string(computeNodeCount)
      }
      {
        name: 'compute_node_cpus'
        value: string(computeNodeCpuCores)
      }
    ]
    scriptContent: loadTextContent('SetupCluster.sh')
  }
}
