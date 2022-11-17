targetScope = 'resourceGroup'

param vnet1Name string = 'vnet1'
param vnet2Name string = 'vnet2'

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

param location string = resourceGroup().location

module vnet1 'modules/virtualNetwork2Subnets.bicep' = {
  name: 'vnet1'
  scope: resourceGroup()
  params:{
    vnetName: vnet1Name
    addressPrefixes:[
    '10.0.0.0/8'
    ]
    subnet1Name:'snet-${vnet1Name}-01'
    subnet2Name:'snet-${vnet1Name}-02'
    subnet1AddressPrefix: '10.1.1.0/24'
    subnet2AddressPrefix: '10.1.2.0/24'
  }
}

module vnet2 'modules/virtualNetwork2Subnets.bicep' = {
  name: 'vnet2'
  scope: resourceGroup()
  params:{
    vnetName: vnet2Name
    addressPrefixes: [
      '172.16.0.0/16'
    ]
    subnet1Name:'snet-${vnet2Name}-01'
    subnet2Name:'snet-${vnet2Name}-02'
    subnet1AddressPrefix: '172.16.1.0/24'
    subnet2AddressPrefix: '172.16.2.0/24'
  }
}

module peering1 'modules/vnetPeering.bicep' = {
  name: 'peering1'
  scope: resourceGroup()
  dependsOn:[
    vnet1
    vnet2
  ]
  params:{
    localVnetName:vnet1Name
    remoteVnetName: vnet2Name
    remoteVnetRg: resourceGroup().name
  }
}

module peering2 'modules/vnetPeering.bicep' = {
  name: 'peering2'
  scope: resourceGroup()
  dependsOn: [
    vnet2
    vnet1
  ]
  params:{
    localVnetName:vnet2Name
    remoteVnetName: vnet1Name
    remoteVnetRg: resourceGroup().name
  }
}


module vm1 'modules/virtualMachine.bicep' = {
  name: 'vm1'
  scope: resourceGroup()
  dependsOn: [
    vnet1
  ]
  params:{
     location: location
      vmName: 'vm1'
      adminPassword: adminPassword
      adminUsername: 'azureuser'
      vNetName: vnet1Name
      subnetName: 'snet-${vnet1Name}-01'
  }
}

module vm2 'modules/virtualMachine.bicep' = {
  name: 'vm2'
  scope: resourceGroup()
  dependsOn: [
    vnet2
  ]
  params:{
     location: location
      vmName: 'vm2'
      adminPassword: adminPassword
      adminUsername: 'azureuser'
      vNetName: vnet2Name
      subnetName: 'snet-${vnet2Name}-01'
  }
}
