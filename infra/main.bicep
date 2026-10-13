targetScope = 'resourceGroup'

@description('Region for all resources')
param location string = resourceGroup().location

@minLength(3)
@maxLength(12)
@description('Short prefix for resource names')
param namePrefix string = 'lab663'

@description('Foundry project name')
param projectName string = 'trailmate'

@description('Object ID of the learner who gets access')
param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
])
@description('Type of the principal in principalId')
param principalType string = 'User'

@description('Deployment SKU')
param skuName string = 'GlobalStandard'

@description('Capacity for each deployment, in thousands of tokens per minute')
param capacity int = 250

@description('Chat models to deploy, named after the model')
param chatModels chatModel[] = [
  { name: 'gpt-5.4', version: '2026-03-05' }
  { name: 'gpt-5.4-mini', version: '2026-03-17' }
]

@description('Model name used by every router edition')
param routerModelName string = 'model-router'

@description('Model router version')
param routerModelVersion string = '2025-11-18'

@description('Model router editions to deploy')
param routerEditions routerEdition[] = [
  { name: 'mr-default' }
  { name: 'mr-cost', mode: 'cost' }
  { name: 'mr-quality', mode: 'quality' }
  {
    name: 'mr-subset'
    mode: 'balanced'
    models: [
      { name: 'gpt-5.6-sol', version: '2026-07-09' }
      { name: 'gpt-5.6-luna', version: '2026-07-09' }
      { name: 'gpt-5.4', version: '2026-03-05' }
      { name: 'gpt-5.4-mini', version: '2026-03-17' }
      { name: 'gpt-5.4-nano', version: '2026-03-17' }
    ]
  }
]

type chatModel = {
  name: string
  version: string
}

type routerEdition = {
  name: string
  mode: ('cost' | 'balanced' | 'quality')?
  models: chatModel[]?
}

var token = take(uniqueString(resourceGroup().id), 6)
var accountName = 'aif-${namePrefix}-${token}'

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    logAnalyticsName: 'log-${namePrefix}-${token}'
    applicationInsightsName: 'appi-${namePrefix}-${token}'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'appi-${namePrefix}-${token}'
  dependsOn: [
    monitoring
  ]
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    location: location
    accountName: accountName
    projectName: projectName
    skuName: skuName
    capacity: capacity
    chatModels: chatModels
    routerModelName: routerModelName
    routerModelVersion: routerModelVersion
    routerEditions: routerEditions
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    applicationInsightsConnectionString: appInsights.properties.ConnectionString
  }
}

module roles 'modules/roles.bicep' = {
  name: 'roles'
  params: {
    accountName: foundry.outputs.accountName
    projectName: foundry.outputs.projectName
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    principalId: principalId
    principalType: principalType
    projectPrincipalId: foundry.outputs.projectPrincipalId
  }
}

output accountName string = foundry.outputs.accountName
output projectName string = foundry.outputs.projectName
output projectEndpoint string = foundry.outputs.projectEndpoint
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
