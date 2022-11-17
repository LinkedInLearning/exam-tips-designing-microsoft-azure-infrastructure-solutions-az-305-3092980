param location string = resourceGroup().location

@description('Domain name for DNS')
param domainNameLabel string

@description('The name of the API publisher. This information is used by API Management.')
param publisherName string = 'AZ305 Org'

@description('The email address of the API publisher. This information is used by API Management.')
param publisherEmail string = 'az305.demos@az305.org'

@description('The name of the SKU to use when creating the API Management service instance. This must be a SKU that supports virtual network integration.')
@allowed([
  'Developer'
  'Premium'
])
param skuName string = 'Developer'

@description('The number of worker instances of your API Management service that should be provisioned.')
param skuCount int = 1

@description('The type of virtual network integration to deploy. In \'External\' mode, a public IP address will be associated with the API Management service instance. In \'Internal\' mode, the instance is only accessible using private networking.')
@allowed([
  'External'
  'Internal'
])
param virtualNetworkType string = 'External'

@description('The IP address prefix (CIDR range) to use when deploying the virtual network.')
param vnetIPPrefix string = '10.0.0.0/16'

@description('The IP address prefix (CIDR range) to use when deploying the API Management subnet within the virtual network.')
param apiManagementSubnetIPPrefix string = '10.0.1.0/24'

@description('The IP address prefix (CIDR range) to use when deploying the API Management subnet within the virtual network.')
param funcSubnetIPPrefix string = '10.0.0.0/24'

@description('The name of the API Management service instance to create. This must be globally unique.')
var serviceName = 'apim-${uniqueString(resourceGroup().id)}'

var vnetName = 'vnet-app'
var apiManagementSubnetName = 'snet-apim'
var funcSubnetName = 'snet-func'
var nsgName = 'nsg-snet-apim'

@description('Name of your Private Endpoint')
param privateEndpointName string = 'pe-${uniqueString(resourceGroup().id)}'

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionName string = 'pel-${uniqueString(resourceGroup().id)}'

@description('The name of the storage account for the functionapp')
var storageAccountName = 'sa${uniqueString(resourceGroup().id)}'

@description('The name of the hosting plan')
var hostingPlanName = 'hp-${uniqueString(resourceGroup().id)}'

@description('The name of the funciton app')
var functionAppName = 'fa-${uniqueString(resourceGroup().id)}'

@description('The name of the Public IP address')
var publicIPName = 'ip-${uniqueString(resourceGroup().id)}'

var fqdn = '${domainNameLabel}.${location}.cloudapp.azure.com'

var repoURL = 'https://github.com/Azure-Samples/functions-quickstart-javascript.git'

var branch = 'main'

var webAppPublicDNSZoneForwarder = ((toLower(environment().name) == 'azureusgovernment') ? '.azurewebsites.us' : '.azurewebsites.net')

var privateDNSZoneName = 'privatelink.azurewebsites.net'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource publicip 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name:  publicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: domainNameLabel
      fqdn: fqdn
    }
  }
  sku: {
    name:  'Standard'
    tier:  'Regional'
  }
  zones: [
    '1','2','3'
  ]
} 

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 20
    perSiteScaling: true
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    hostNameSslStates: [
      {
        name: '${toLower(functionAppName)}${webAppPublicDNSZoneForwarder}'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${toLower(functionAppName)}.scm${webAppPublicDNSZoneForwarder}'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: hostingPlan.id
  }
}

//This is required for the sourcecontrols section to complete properly
//otherwise can get conflict errors or missing files and a null branch name
resource config 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    WEBSITE_NODE_DEFAULT_VERSION: '~18'
    WEBSITE_CONTENTSHARE: toLower(functionAppName)
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
    WEBSITE_VNET_ROUTE_ALL: '1'
    WEBSITE_DNS_SERVER: '168.63.129.16'
  }
  dependsOn: [
    sourcecontrol
  ]
}

resource sourcecontrol 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true
  }
}


resource apiManagementService 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: serviceName
  location: location
  sku: {
    name: skuName
    capacity: skuCount
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
    virtualNetworkType: virtualNetworkType
    virtualNetworkConfiguration: {
      subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets',vnet.name ,apiManagementSubnetName)
    }
    publicIpAddressId: publicip.id
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetIPPrefix
      ]
    }
    subnets: [
      {
        name: apiManagementSubnetName
        properties: {
          addressPrefix: apiManagementSubnetIPPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
            }
          ]
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: funcSubnetName
        properties: {
          addressPrefix: funcSubnetIPPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      // Rules for API Management as documented here: https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet
      {
        name: 'Client_communication_to_API_Management'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Secure_Client_communication_to_API_Management'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Management_endpoint_for_Azure_portal_and_Powershell'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'Dependency_on_Azure_Storage'
        properties: {
          description: 'APIM service dependency on Azure Blob and Azure Table Storage'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'Azure_Active_Directory_and_Azure_KeyVault_dependency'
        properties: {
          description: 'Connect to Azure Active Directory for Developer Portal Authentication or for Oauth2 flow during any Proxy Authentication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'Access_to_Azure_SQL_endpoints'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 150
          direction: 'Outbound'
        }
      }
      {
        name: 'Access_to_Azure_KeyVault'
        properties: {
          description: 'Allow APIM service control plane access to KeyVault to refresh secrets'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault'
          access: 'Allow'
          priority: 160
          direction: 'Outbound'
        }
      }
      {
        name: 'Dependency_for_Log_to_event_Hub_policy_and_monitoring_agent'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '5671'
            '5672'
            '443'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 170
          direction: 'Outbound'
        }
      }
      {
        name: 'Dependency_on_Azure_File_Share_for_GIT'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 180
          direction: 'Outbound'
        }
      }
      {
        name: 'Health_and_Monitoring_Extension'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '443'
            '12000'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 190
          direction: 'Outbound'
        }
      }
      {
        name: 'Publish_Diagnostic_Logs_and_Metrics_Resource_Health_and_Application_Insights'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '1886'
            '443'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Connect_To_SMTP_Relay_for_sending_e-mails'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '25'
            '587'
            '25028'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 210
          direction: 'Outbound'
        }
      }
      {
        name: 'Access_Redis_Service_for_Cache_policies_between_machines'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6381-6383'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 220
          direction: 'Inbound'
        }
      }
      {
        name: 'Sync_Counters_for_Rate_Limit_policies_between_machines'
        properties: {
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '4290'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 230
          direction: 'Inbound'
        }
      }
      {
        name: 'Azure_Infrastructure_Load_Balancer'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 240
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',vnet.name ,funcSubnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZoneName
  location: 'global'
  dependsOn: [
    vnet
  ]
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones
  name: '${privateDnsZones.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZones.id
        }
      }
    ]
  }
}
