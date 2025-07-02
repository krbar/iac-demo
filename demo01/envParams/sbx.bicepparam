using '../main.bicep'

var namePrefix = '<your-name-prefix>' // TODO: Replace with your name prefix, 4-5 characters, lowercase, no special characters
var projectName = 'demo01'
var environment = 'sbx'

param location =  'uksouth' // Change to your preferred Azure region

param resourceGroupName =  '${namePrefix}-${projectName}-${environment}-rg'

param logAnalyticsWorkspaceName = '${namePrefix}-${projectName}-${environment}-law'
param storageAccountName = '${namePrefix}${projectName}${environment}sa'
param vnetName = '${namePrefix}-${projectName}-${environment}-vnet'

param appServicePlanName = '${namePrefix}-${projectName}-${environment}-asp'
param appServiceName = '${namePrefix}-${projectName}-${environment}-app'
param appServiceIdentityName = '${namePrefix}-${projectName}-${environment}-id'
param appInsightsName = '${namePrefix}-${projectName}-${environment}-appi'

