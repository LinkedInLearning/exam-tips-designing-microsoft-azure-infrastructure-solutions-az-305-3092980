@description('Admin username for authentication')
param adminUsername string

@description('Password for the admin username')
@minLength(12)
@secure()
param adminPassword string

@description('Static prefix for the server')
@minLength(3)
@maxLength(11)
param serverPrefix string

@description('Tier and compute tier')
@allowed([
  'GP_Gen5_2'
  'GP_Gen5_4'
  'GP_Gen5_8'
])
param skuName string = 'GP_Gen5_2'

param maxSizeBytes int = 34359738368

@description('Allowed values for vCore')
@allowed([
  'GeneralPurpose'
  'BusinessCritical'
])
param skuTier string = 'GeneralPurpose'

var uniqueServerName = '${serverPrefix}${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

resource sqlserver 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: uniqueServerName
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
  }
  resource sqldb 'databases@2021-11-01-preview' = {
    name: 'vcoredb'
    location: location
    sku: {
      name: skuName
      tier: skuTier
    }
    properties: {
      maxSizeBytes: maxSizeBytes
    }
  }
}
