param vnetName string
param addressPrefixes array
param subnet1Name string
param subnet2Name string
param subnet1AddressPrefix string
param subnet2AddressPrefix string
param location string = resourceGroup().location

var networkSecurityGroupName = '${vnetName}-NSG'

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  location: location
  name: vnetName
  properties:{
    addressSpace:{
      addressPrefixes:addressPrefixes 
    }
    subnets:[
      {
        name:subnet1Name
        properties:{
          addressPrefix: subnet1AddressPrefix
          networkSecurityGroup: {
            id: securityGroup.id
          }          
        }
      }
      {
        name:subnet2Name
        properties:{
          addressPrefix: subnet2AddressPrefix          
        }
      }
    ]    
  }
}

