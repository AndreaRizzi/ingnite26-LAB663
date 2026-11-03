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

@description('Optional service principal that bootstraps the agent for a Skillable learner')
param bootstrapPrincipalId string = ''

@description('Create role assignments. Set false when all roles are managed outside this template.')
param assignRoles bool = true

@description('Create learner role assignments. Set false when Skillable already grants learner access.')
param assignLearnerRoles bool = true

@description('Ownership tags used by the lifecycle scripts')
param resourceTags object = {}

@description('Deployment SKU')
param skuName string = 'GlobalStandard'

@description('Capacity for each deployment, in thousands of tokens per minute')
@minValue(1)
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
    resourceTags: resourceTags
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
    resourceTags: resourceTags
  }
}

module roles 'modules/roles.bicep' = if (assignRoles) {
  name: 'roles'
  params: {
    accountName: foundry.outputs.accountName
    projectName: foundry.outputs.projectName
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    principalId: principalId
    principalType: principalType
    assignLearnerRoles: assignLearnerRoles
    projectPrincipalId: foundry.outputs.projectPrincipalId
    bootstrapPrincipalId: bootstrapPrincipalId
  }
}

output accountName string = foundry.outputs.accountName
output projectName string = foundry.outputs.projectName
output projectEndpoint string = foundry.outputs.projectEndpoint
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
output chatModelDeploymentNames array = foundry.outputs.chatModelDeploymentNames
output managedResourceIds array = [
  foundry.outputs.accountId
  monitoring.outputs.applicationInsightsId
  monitoring.outputs.workspaceId
]
