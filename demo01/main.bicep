targetScope = 'subscription'

@description('The name of the resource group to deploy the resources to.')
param resourceGroupName string

@description('The name of the log analytics workspace to create.')
param logAnalyticsWorkspaceName string

@description('The name of the storage account to create.')
param storageAccountName string

@description('The name of the virtual network to create.')
param vnetName string

@description('The name of the application insights resource to create.')
param appInsightsName string

@description('The name of the app service plan to create.')
param appServicePlanName string

@description('The name of the app service to create.')
param appServiceName string

@description('The name of the managed identity to create.')
param appServiceIdentityName string

@description('The location to deploy the resources to.')
param location string

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
}

module logs 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  scope: rg
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    diagnosticSettings: [
      {
        useThisWorkspace: true
      }
    ]
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  scope: rg
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'endpoint-subnet'
        addressPrefix: '10.0.0.0/24'
      }
      {
        name: 'app-subnet'
        addressPrefix: '10.0.1.0/24'
        delegation: 'Microsoft.Web/serverFarms'
      }
    ]
    diagnosticSettings: [
      {
        workspaceResourceId: logs.outputs.resourceId
      }
    ]
  }
}

module blobPrivateDNSZone 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  scope: rg
  params: {
    name: 'privatelink.blob.${environment().suffixes.storage}'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnet.outputs.resourceId
      }
    ]
  }
}

module storage 'br/public:avm/res/storage/storage-account:0.23.0' = {
  scope: rg
  params: {
    name: storageAccountName
    location: location
    allowSharedKeyAccess: false
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    diagnosticSettings: [
      {
        workspaceResourceId: logs.outputs.resourceId
      }
    ]
    blobServices: {
      containers: [
        {
          name: 'myfiles'
          publicAccess: 'None'
          roleAssignments: [
            {
              principalId: appIdentity.outputs.principalId
              principalType: 'ServicePrincipal'
              roleDefinitionIdOrName: 'Storage Blob Data Contributor'
            }
          ]
        }
      ]
      diagnosticSettings: [
        {
          workspaceResourceId: logs.outputs.resourceId
        }
      ]
    }
    privateEndpoints: [
      {
        service: 'blob'
        subnetResourceId: vnet.outputs.subnetResourceIds[0]
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: blobPrivateDNSZone.outputs.resourceId
            }
          ]
        }
      }
    ]
    networkAcls: {
      bypass: 'AzureServices, Logging'
      defaultAction: 'Deny'
    }
    roleAssignments: [
      {
        principalId: appIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Reader'
      }
    ]
  }
}

module asp 'br/public:avm/res/web/serverfarm:0.4.1' = {
  scope: rg
  params: {
    name: appServicePlanName
    location: location
    kind: 'linux'
    skuName: 'P0v3'
    skuCapacity: 2
    reserved: true
    zoneRedundant: true
    diagnosticSettings: [
      {
        workspaceResourceId: logs.outputs.resourceId
      }
    ]
  }
}

module appi 'br/public:avm/res/insights/component:0.6.0' = {
  scope: rg
  params: {
    name: appInsightsName
    workspaceResourceId: logs.outputs.resourceId
    location: location
    applicationType: 'web'
    diagnosticSettings: [
      {
        workspaceResourceId: logs.outputs.resourceId
      }
    ]
  }
}

module appIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  scope: rg
  params: {
    name: appServiceIdentityName
    location: location
  }
}

module app 'br/public:avm/res/web/site:0.16.0' = {
  scope: rg
  params: {
    name: appServiceName
    location: location
    kind: 'app,linux'
    serverFarmResourceId: asp.outputs.resourceId
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      linuxFxVersion: 'DOTNETCORE|9.0'
    }
    configs: [
      {
        name: 'appsettings'
        applicationInsightResourceId: appi.outputs.resourceId
        properties: {
          AZURE_STORAGE_ACCOUNT_NAME: storage.outputs.name
          AZURE_STORAGE_CONTAINER_NAME: 'myfiles'
          ManagedIdentityClientId: appIdentity.outputs.clientId
        }
      }
    ]
    managedIdentities: {
      userAssignedResourceIds: [
        appIdentity.outputs.resourceId
      ]
    }
    virtualNetworkSubnetId: vnet.outputs.subnetResourceIds[1]
    diagnosticSettings: [
      {
        workspaceResourceId: logs.outputs.resourceId
      }
    ]
  }
}
