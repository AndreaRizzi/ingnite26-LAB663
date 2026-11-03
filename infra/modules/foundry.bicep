@description('Region for the Foundry resource')
param location string

@description('Foundry (AI Services) account name; also its custom subdomain')
param accountName string

@description('Foundry project name')
param projectName string

@description('Deployment SKU')
param skuName string

@description('Capacity for each deployment, in thousands of tokens per minute')
param capacity int

@description('Chat models to deploy, named after the model')
param chatModels chatModel[]

@description('Model name used by every router edition')
param routerModelName string

@description('Model router version')
param routerModelVersion string

@description('Model router editions to deploy')
param routerEditions routerEdition[]

@description('Application Insights resource ID to connect to the project for tracing')
param applicationInsightsId string

@secure()
@description('Application Insights connection string')
param applicationInsightsConnectionString string

param resourceTags object = {}

type chatModel = {
  name: string
  version: string
}

type routerEdition = {
  name: string
  mode: ('cost' | 'balanced' | 'quality')?
  models: chatModel[]?
}

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
      capacity: capacity
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
      capacity: capacity
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: routerModelName
        version: routerModelVersion
      }
      // No routing block means the router's own defaults.
      routing: empty(e.?mode) && empty(e.?models)
        ? null
        : {
            mode: e.?mode
            models: empty(e.?models)
              ? null
              : map(e.?models ?? [], m => {
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
    target: applicationInsightsId
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: applicationInsightsConnectionString
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: applicationInsightsId
    }
  }
  dependsOn: [
    routerDeployments
  ]
}

output accountName string = account.name
output accountId string = account.id
output projectName string = project.name
output projectEndpoint string = 'https://${account.name}.services.ai.azure.com/api/projects/${project.name}'
output projectPrincipalId string = project.identity.principalId
output chatModelDeploymentNames array = [for (model, i) in chatModels: chatDeployments[i].name]
