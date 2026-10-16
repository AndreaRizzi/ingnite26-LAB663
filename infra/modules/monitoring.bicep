@description('Region for the monitoring resources')
param location string

@description('Log Analytics workspace name')
param logAnalyticsName string

@description('Application Insights name')
param applicationInsightsName string

param resourceTags object = {}

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

output applicationInsightsName string = appInsights.name
output applicationInsightsId string = appInsights.id
output workspaceId string = workspace.id
