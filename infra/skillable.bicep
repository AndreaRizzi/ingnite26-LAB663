targetScope = 'resourceGroup'

@description('Deploy LAB663 resources to East US or West US, independently of the allocated group location.')
@allowed([
  'eastus'
  'westus'
])
param location string = 'eastus'

@minLength(1)
@maxLength(40)
@description('Skillable lab instance ID. Use the same ID in the VM lifecycle and teardown.')
param labInstanceId string

@minLength(36)
@maxLength(36)
@description('Entra object ID of the learner, not their UPN.')
param learnerObjectId string

@minLength(36)
@maxLength(36)
@description('Object ID of the lifecycle service principal, not its application/client ID.')
param bootstrapObjectId string

@minValue(1)
@description('Capacity for each of the six model deployments. Check regional subscription quota before provisioning.')
param capacity int = 250

// Reuse the self-guided resource definitions so model versions, routing and role IDs stay aligned.
module resources 'main.bicep' = {
  name: 'lab663-resources'
  params: {
    location: location
    principalId: learnerObjectId
    principalType: 'User'
    bootstrapPrincipalId: bootstrapObjectId
    assignRoles: true
    capacity: capacity
    resourceTags: {
      lab663Instance: labInstanceId
      lab663ManagedBy: 'lifecycle'
    }
  }
}

output accountName string = resources.outputs.accountName
output projectName string = resources.outputs.projectName
output projectEndpoint string = resources.outputs.projectEndpoint
output applicationInsightsName string = resources.outputs.applicationInsightsName
output chatModelDeploymentNames array = resources.outputs.chatModelDeploymentNames
output managedResourceIds array = resources.outputs.managedResourceIds
output labInstanceId string = labInstanceId
output learnerObjectId string = learnerObjectId
output bootstrapObjectId string = bootstrapObjectId
output location string = location
output capacity int = capacity
