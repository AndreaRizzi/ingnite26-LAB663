@description('Foundry account name')
param accountName string

@description('Foundry project name')
param projectName string

@description('Application Insights name')
param applicationInsightsName string

@description('Object ID of the learner who gets access')
param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
])
param principalType string = 'User'

@description('Object ID of the project managed identity')
param projectPrincipalId string

param bootstrapPrincipalId string = ''

@description('Create learner roles while retaining bootstrap and project-identity roles.')
param assignLearnerRoles bool = true

@description('Learner role definition IDs the learner already holds; these are not assigned again.')
param skipLearnerRoleIds array = []

// Built-in role definition IDs. We use IDs so the roles survive renames.
var foundryUserRoleId = '53ca6127-db72-4b80-b1b0-d745d6d5456d'
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'
var monitoringReaderRoleId = '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
var logAnalyticsReaderRoleId = '73c42c96-874c-492b-b04d-ab87d138a893'

resource account 'Microsoft.CognitiveServices/accounts@2026-09-01' existing = {
  name: accountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

// The names use the project name, not its principal ID, so they resolve at the start of the deployment.
resource learnerFoundryUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignLearnerRoles && !contains(skipLearnerRoleIds, foundryUserRoleId)) {
  name: guid(account.id, principalId, foundryUserRoleId)
  scope: account
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', foundryUserRoleId)
  }
}

// MAI voice and transcription use Speech, which needs this role for keyless sign-in.
resource learnerCognitiveServicesUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignLearnerRoles && !contains(skipLearnerRoleIds, cognitiveServicesUserRoleId)) {
  name: guid(account.id, principalId, cognitiveServicesUserRoleId)
  scope: account
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
  }
}

resource bootstrapFoundryUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(bootstrapPrincipalId) && bootstrapPrincipalId != principalId) {
  name: guid(account.id, bootstrapPrincipalId, foundryUserRoleId)
  scope: account
  properties: {
    principalId: bootstrapPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', foundryUserRoleId)
  }
}

resource projectFoundryUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(account.id, projectName, foundryUserRoleId)
  scope: account
  properties: {
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', foundryUserRoleId)
  }
}

resource projectMetricsPublisher 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appInsights.id, projectName, monitoringMetricsPublisherRoleId)
  scope: appInsights
  properties: {
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherRoleId)
  }
}

resource projectMonitoringReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appInsights.id, projectName, monitoringReaderRoleId)
  scope: appInsights
  properties: {
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringReaderRoleId)
  }
}

resource learnerLogAnalyticsReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignLearnerRoles && !contains(skipLearnerRoleIds, logAnalyticsReaderRoleId)) {
  name: guid(appInsights.id, principalId, logAnalyticsReaderRoleId)
  scope: appInsights
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logAnalyticsReaderRoleId)
  }
}
