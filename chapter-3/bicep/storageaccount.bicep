@description('Static prefix for the storage account')
@minLength(3)
@maxLength(11)
param storagePrefix string

@description('Allowed values for storageSKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSKU string = 'Standard_LRS'

@description('Azure region where resources will be deployed, pulled from resourceGroup')
param location string = resourceGroup().location

@description('UTC timestamp used to create distinct deployment scripts for each deployment')
param utcValue string = utcNow()

var uniqueStorageName = '${storagePrefix}${uniqueString(resourceGroup().id)}'

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: uniqueStorageName
  location: location
  sku: {
    name: storageSKU
  }
  properties: {
    allowBlobPublicAccess: true
  }
  kind: 'StorageV2'

  resource fileService 'fileServices' = {
    name: 'default'
    properties: {
      shareDeleteRetentionPolicy: {
        days: 1
        enabled: true
      }
    }

    resource share 'shares' = {
      name: 'share1'
      properties: {
        accessTier: 'Hot'
      }
    }
  }
  resource blobService 'blobServices' = {
    name: 'default'
    properties: {
      containerDeleteRetentionPolicy: {
        days: 7
        enabled: true
      }
      deleteRetentionPolicy: {
        days: 7
        enabled: true
      }
      isVersioningEnabled: true
    }

    resource firstContainer 'containers' = {
      name: 'text'
      properties: {
        publicAccess : 'Container'
      }
    }
    resource secondContainer 'containers' = {
      name: 'json'
      properties: {
        publicAccess : 'Container'
      }
    }
  }

  
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployscript-upload-blob-${utcValue}'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: stg.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: stg.listKeys().keys[0].value
      }
      {
        name: 'TXTCONTENT'
        value: loadTextContent('../../data/blob.txt')
      }
      {
        name: 'JSONCONTENT'
        value: loadTextContent('../../data/blob.json')
      }
    ]
    scriptContent: '''
                        echo "$TXTCONTENT" > blob.txt
                        echo "$JSONCONTENT" > blob.json

                        az storage blob upload --file blob.txt --container-name text --name blob.txt

                        az storage blob upload --file blob.txt --container-name text --name blob-2.txt

                        az storage blob upload --file blob.json --container-name json --name blob.json

                        az storage blob upload --file blob.json --container-name json --name blob-2.json
                  '''
  }
}

output storageEndpoint object = stg.properties.primaryEndpoints

