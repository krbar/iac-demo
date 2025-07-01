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
