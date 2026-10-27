// LAB663 for Skillable: one self-contained template for the lab's Azure resources.
//
// Skillable pastes this into a lab profile's Resource Template and deploys it into the
// lab's resource group at launch. It creates:
//   - Log Analytics and Application Insights (tracing)
//   - A Foundry resource and the `trailmate` project, connected to Application Insights
//   - Two chat model deployments and four model router editions
//   - Role assignments for the project's managed identity (and the learner, when supplied)
//
// It does not write the learner's .env or create the v0 agent. Those run on the learner's
// machine afterwards: instructions/skillable/setenv.sh, then src/agent/01_build_agent.py.
//
// Role assignments need an identity that can assign roles (Owner, User Access Administrator
// or Role Based Access Control Administrator). Set assignRoles=false when deploying as the
// learner, who can't (see test-deploy.sh).

targetScope = 'resourceGroup'

@allowed([
  'swedencentral'
  'eastus'
  'eastus2'
])
@description('Region for every resource. Limited to regions where we checked all lab models and features.')
param location string = 'swedencentral'

@minValue(1)
@maxValue(1000)
@description('Capacity for gpt-5.4, in thousands of tokens per minute. It runs the agent and the evaluation judge, so it needs the most.')
param frontierCapacity int = 250

@minValue(1)
@maxValue(1000)
@description('Capacity for gpt-5.4-mini, in thousands of tokens per minute.')
param smallCapacity int = 150

@minValue(1)
@maxValue(1000)
@description('Capacity for each of the four model router editions, in thousands of tokens per minute.')
param routerCapacity int = 150

@description('Create role assignments. Needs an identity that can assign roles; false when the learner deploys.')
param assignRoles bool = true

@description('Optional learner object ID. When set (and assignRoles is true), the learner gets Foundry User and Log Analytics Reader on the lab resources.')
param principalId string = ''

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
])
@description('Type of the principal in principalId')
param principalType string = 'User'

@description('Tags for every resource')
param resourceTags object = {}

// Names the notebooks and setenv.sh expect. Keep these in step with src/lab.py.
var namePrefix = 'lab663'
var projectName = 'trailmate'
var token = take(uniqueString(resourceGroup().id), 6)
var accountName = 'aif-${namePrefix}-${token}'
var logAnalyticsName = 'log-${namePrefix}-${token}'
var applicationInsightsName = 'appi-${namePrefix}-${token}'
var skuName = 'GlobalStandard'

var chatModels = [
  { name: 'gpt-5.4', version: '2026-03-05', capacity: frontierCapacity }
  { name: 'gpt-5.4-mini', version: '2026-03-17', capacity: smallCapacity }
]

var routerModel = { name: 'model-router', version: '2025-11-18' }

// Every edition has the same shape (empty mode or models means the router's default).
var routerEditions = [
  { name: 'mr-default', mode: '', models: [] }
  { name: 'mr-cost', mode: 'cost', models: [] }
  { name: 'mr-quality', mode: 'quality', models: [] }
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

// Built-in role definition IDs. We use IDs so the roles survive renames.
var foundryUserRoleId = '53ca6127-db72-4b80-b1b0-d745d6d5456d'
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'
var monitoringReaderRoleId = '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
var logAnalyticsReaderRoleId = '73c42c96-874c-492b-b04d-ab87d138a893'
var assignLearnerRoles = assignRoles && !empty(principalId)

// --- Monitoring ---

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: resourceTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: resourceTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

// --- Foundry ---

resource account 'Microsoft.CognitiveServices/accounts@2026-09-01' = {
  name: accountName
  location: location
  tags: resourceTags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2026-09-01' = {
  parent: account
  name: projectName
  location: location
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectName
  }
}

// The account accepts one change at a time: project first, then chat models, then routers, then the connection.
@batchSize(1)
resource chatDeployments 'Microsoft.CognitiveServices/accounts/deployments@2026-09-01' = [
  for m in chatModels: {
    parent: account
    name: m.name
    sku: {
      name: skuName
      capacity: m.capacity
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: m.name
        version: m.version
      }
    }
    dependsOn: [
      project
    ]
  }
]

@batchSize(1)
resource routerDeployments 'Microsoft.CognitiveServices/accounts/deployments@2026-09-01' = [
  for e in routerEditions: {
    parent: account
    name: e.name
    sku: {
      name: skuName
      capacity: routerCapacity
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: routerModel.name
        version: routerModel.version
      }
      // No routing block means the router's own defaults.
      routing: empty(e.mode) && empty(e.models)
        ? null
        : {
            mode: empty(e.mode) ? null : e.mode
            models: empty(e.models)
              ? null
              : map(e.models, m => {
                  format: 'OpenAI'
                  name: m.name
                  version: m.version
                })
          }
    }
    dependsOn: [
      chatDeployments
    ]
  }
]

// Lets the Foundry portal show traces for agents in this project.
resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2026-09-01' = {
  parent: project
  name: 'appinsights'
  properties: {
    category: 'AppInsights'
    target: appInsights.id
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: appInsights.properties.ConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsights.id
    }
  }
  dependsOn: [
    routerDeployments
  ]
}

// --- Role assignments ---
// Names use the project name, not its principal ID, so they resolve at the start of the deployment.

resource projectFoundryUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignRoles) {
  name: guid(account.id, projectName, foundryUserRoleId)
  scope: account
  properties: {
    principalId: project.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', foundryUserRoleId)
  }
}

resource projectMetricsPublisher 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignRoles) {
  name: guid(appInsights.id, projectName, monitoringMetricsPublisherRoleId)
  scope: appInsights
  properties: {
    principalId: project.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherRoleId)
  }
}

resource projectMonitoringReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignRoles) {
  name: guid(appInsights.id, projectName, monitoringReaderRoleId)
  scope: appInsights
  properties: {
    principalId: project.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringReaderRoleId)
  }
}

resource learnerFoundryUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignLearnerRoles) {
  name: guid(account.id, principalId, foundryUserRoleId)
  scope: account
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', foundryUserRoleId)
  }
}

resource learnerLogAnalyticsReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignLearnerRoles) {
  name: guid(appInsights.id, principalId, logAnalyticsReaderRoleId)
  scope: appInsights
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logAnalyticsReaderRoleId)
  }
}

output location string = location
output accountName string = account.name
output projectName string = project.name
output projectEndpoint string = 'https://${account.name}.services.ai.azure.com/api/projects/${project.name}'
output applicationInsightsName string = appInsights.name
