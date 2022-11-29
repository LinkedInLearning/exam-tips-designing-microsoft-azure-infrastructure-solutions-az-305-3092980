# az-305-tips
Repository for demos shown in LinkedIn Learning AZ-305 tips

The bicep files are designed to be run from bash in cloudshell

## Video 01_01 - Logging and Monitoring

1. Create Application Insights Demo

    The demo uses this GItHub Repo:

    https://github.com/MicrosoftDocs/mslearn-monitoring-java

    Clone it into Azure CloudShell and then use code . to edit the deployPetClinicApp.sh file to setup naming and credentials.

    Now run ./deployPetClinicApp.sh it takes abount 30mins

    Once that is complete, [add an availability test](https://learn.microsoft.com/en-us/azure/azure-monitor/app/availability-standard-tests)

    For the demo I took the site down overnight so that it wasn't all green.

2. Create two peered VMs

    This is for the flow log demo

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter1 --location <location>

    az deployment group create --name 'c1-flowlog' --resource-group rg-chapter1 --template-file ./chapter-1/bicep/peeredvnetvms.bicep
    ```

    Enable traffic analytics to the Log Analytics workspace created in Step 1

    Ping from one VM to the other continuously

    The install telnet client on the other

    ```Install-WindowsFeater Telnet-Client```

    Use telnet to try to contact ports that are closed

    And checkout the analytics after about 30mins, it takes a while to pick it all up

## Video 01_02 - Design Authentication and Authorization solutions

1. Create a Key Vault and Assign RBAC

    This is the Key Vault shown in video 01_01 for assigning RBAC roles to a user

    And assign a data reader role to your own user

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter1 --location <location>

    az deployment group create --name 'c1-kvault' --resource-group rg-chapter1 --template-file ./chapter-1/bicep/keyvault-rbac.bicep
    ```

## Video 01_03 - Design identities and access for applications

1. Create the functionapp and storage MSI environment

    Open CLoudshell and clone the github repo

    ```
    git clone https://github.com/Azure-Samples/functions-storage-managed-identity.git
    ```

    CD into the cloned fodler and run code . to open visual studio code

    Edit src\Functions.cs and change line 90 from 

    ```
    ExpiresOn = DateTimeOffset.UtcNow + TimeSpan.FromMinutes(1)
    ```

    To

    ```
    ExpiresOn = DateTimeOffset.UtcNow + TimeSpan.FromMinutes(5)
    ```

    This just increases the time the SAS works for, 1 minute is a little quick!

    Edit \StorageMSIFunction.csproj and change line 3 from

    ```
        <TargetFramework>netcoreapp3.1</TargetFramework>
    ```

    To

    ```
        <TargetFramework>netcoreapp6</TargetFramework>

    ```
    
    
    and change line 11 from

    ```
    <PackageReference Include="Microsoft.NET.Sdk.Functions" Version="3.0.13" />
    ```

    To

    ```
    <PackageReference Include="Microsoft.NET.Sdk.Functions" Version="4.1.3" />
    ```

    Edit terraform\provider.tf and change line 3 from

    ```
      required_version = "~> 1.0.0"
    ```

    To
    ```
      required_version = "~> 1.3.2"
    ```

    Ensure that the resource group you are going to use does not exist, then cd into the terraform directory and run

    ```
    az account set --subscription <target subscription ID>
    terraform init
    terraform apply --var basename="<a base name for your resources, e.g. 'bhfxnmsisamp'>" --var resource_group_name="<resource group to create & deploy to>" --var location="<Azure region to deploy, defaults to West US if not specified>"
    ```

    This creates a deploy_app.sh file in the terraform directory, edit it and add --force as a parameter to both commands, then execute

    ```
    ./deploy_app.sh
    ```

    You can now follow the demo


## Video 01_04 - Design Governance

1. Assign a policy that inherits a tag from a resource group when a resource is created

2. Create a custom policy that denies creation of B series VMs and apply it to a resource group, test by trying to create a VM in the resource group


### Video 01_04 Hints

[Create and manage policies to enforce compliance](https://learn.microsoft.com/en-us/azure/governance/policy/tutorials/create-and-manage)

## Video 02_01 - Recommend a data storage solution

1. Create a Free tier Azure Cosmos DB with the SQL API

2. Create a containter, explore the container settings and how RU's work

3. Create a JSON document in the container

4. Create a Standard storage account

5. Create a file share in the standard storage account

6. Create a folder in the file share and upload a file to the folder

7. Look at the connect settings for the fileshare


### Video 02_01 Hints

[Create a container in Cosmos DB](https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/how-to-create-container)

[Create and use an Azure File Share](https://learn.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-portal?tabs=azure-portal)

## Video 02_02 - Design a data storage solution for relational data

1. Create a single database Azure SQL DB, with vCore purchasing model.

    Investigate the purchasing models and their compute and storage options

    Configure to use Azure AD for authentication.

    Investigate the networking methods in the networking tab, including the TLS settings

    Investigate Transparent Data Encryption (TDE) on the security tab

    Choose Sample data source on the Additional Settings tab

2. Connect to the database using SSMS or Azure Data Studio

### Video 02_02 Hints

[Create a single database - Azure SQL Database](https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-create-quickstart?view=azuresql&tabs=azure-portal)

[Connect and query an Azure SQL Database](https://learn.microsoft.com/en-us/sql/ssms/quickstarts/ssms-connect-query-azure-sql?source=recommendations&view=sql-server-ver16)

## Video 02_03 - Design a data storage solution for non-relational data

1. Create a standard storage account with default settings

2. Create a blob container and change the default access tier on the container to cool

3. Create a blob in the container, note the access tier. Now change it to hot.

4. Create a legal hold access policy on the container, then clear the legal hold

[Set the default access tier for a storage account](https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-online-manage?tabs=azure-portal#set-the-default-access-tier-for-a-storage-account)

[Set a blobs access tier](https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-online-manage?tabs=azure-portal)

[Configure or clear a legal hold](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-policy-configure-container-scope?tabs=azure-portal#configure-or-clear-a-legal-hold)

## Video 03_01 - Design Business Continuity Solutions

1. Create a SQL VM

    This SQL VM is shown in video 03_01 for automated backups and the screenshot of a backup policy.

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter3 --location <location>

    az deployment group create --name 'c3-sql-vm' --resource-group rg-chapter3 --template-file ./chapter-3/bicep/sqlvm.bicep
    ```

    adminusername - sqladmin

    adminPassword - Th1s!sAPassw0rd

2. Create a Storage Account

    This Storage Account is shown in the operational backup screenshot in video 03_01

    A file share is also created which can be used to 

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter3 --location <location>

    az deployment group create --name 'c3-storage' --resource-group rg-chapter3  --template-file ./chapter-3/bicep/storageaccount.bicep --parameters storageSKU=Standard_LRS

    ```

3. Create a General Purpose vCore Azure SQL DB

    This Azure SQL DB is shown in the automated backup section of 03_01

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter3 --location <location>

    az deployment group create --resource-group rg-chapter3 --template-file ./chapter-3/bicep/azuresql.bicep
    ```

    adminusername - sqladmin

    adminPassword - Th1s!sAPassw0rd

4. Create a recovery services vault

5. Configure a backup through Azure Backup for the SQLVM created in step 1. 

    When creating the backup policy take a good look at the schedule section to ensure you can determine the RPO and maximum time the VM can be recovered for.

6. Configure a backup for the fileshare created in Step 2

7. Configure operational backup for the blobs created in Step 2

8. Configure long term retention for the Azure SQL DB created in Step 3. **

### Video 03_01 Hints


[Backup a SQL Server database in an Azure VM](https://learn.microsoft.com/en-us/azure/backup/tutorial-sql-backup)

[Backup Azure file shares](https://learn.microsoft.com/en-us/azure/backup/backup-afs)

[Configure operational backup for Azure Blobs](https://learn.microsoft.com/en-us/azure/backup/blob-backup-configure-manage)

[Manage Azure SQL Database long-term backup retention](https://learn.microsoft.com/en-us/azure/azure-sql/database/long-term-backup-retention-configure?view=azuresql&tabs=portal)


## Video 03_02 - Design for High Availability

1. Create a zone redundant public load balancer and balance load for two VM's with IIS in different zones

    When creating the VM, explore the Availability options shown in the portal.

2. Place a reginal load balancer infront of the public load balancer created in step 1

3. Create a General Purpose vCore Azure SQL DB

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter3 --location <location>

    az deployment group create --resource-group rg-chapter3 --template-file ./chapter-3/bicep/azuresql.bicep
    ```

    adminusername - sqladmin

    adminPassword - Th1s!sAPassw0rd

    Open the Compute + storage and verify how the underlying configuration of the choice of service tier effects the cost and availability options.

4. Simulate an Azure Storage region failure

    Follow the tutorial [Build a highly available application with Blob storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-create-geo-redundant-storage?tabs=dotnet)

### Video 03_02 Hints

[Create a public load balancer to load balance VMs using the Azure portal](https://learn.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-public-portal)

[Create a cross-region Azure Load Balancer using the Azure portal](https://learn.microsoft.com/en-us/azure/load-balancer/tutorial-cross-region-portal)


## Video 04_01 and 04_02 - Design a compute solution

1. Create a Web App on S1 tier with autoscale rules and a service bus

    This Web App is shown in video 04_02 when describing autoscale rules and app service plans

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter4 --location <location>

    az deployment group create --resource-group rg-chapter4 --template-file ./chapter-4/bicep/webapp-servicebus.bicep
    ```

    Explore deployment slots, autoscale rules including metrics from other resources and app service plan feature options

    The Service Bus Queues are created for the demo to show autoscale metrics for different resources

2. Create an Azure Batch Account and a pool of compute nodes

    Optionally configure to run a parallel workload. This may not be possible to follow if using the Azure free account

3. Create a PowerShell function with anonymous authorization

4. Follow this tutorial to link Logic Apps with Functions

    [Automate tasks to process emails by using Azure Logic Apps, Azure Functions, and Azure Storage](https://learn.microsoft.com/en-us/azure/logic-apps/tutorial-process-email-attachments-workflow)

5. Create an AKS Cluster

    Manually scale pods and configure your deployment for autoscaling

### Video 04_01 and 04_02 Hints

[Deploy a PHP app to Azure](https://learn.microsoft.com/en-us/azure/app-service/quickstart-php?tabs=cli&pivots=platform-linux)

[Create an Azure Batch account and pool of nodes](https://learn.microsoft.com/en-us/azure/batch/tutorial-parallel-dotnet)

[Run a parallel workload with Azure Batch using the .NET API](https://learn.microsoft.com/en-us/azure/batch/tutorial-parallel-dotnet)

[Create a PowerShell function in Azure](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-powershell)

[Deploy an Azure Kubernetes Service (AKS) cluster using the Azure portal](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal?tabs=azure-cli)

[Prepare an application for Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app)

## Video 04_03 - Design an application architecture

1. Create a Public IP, Function App and API Management instance

    This instance was seen at the end of video 04_02 when looking at the configuration options for Networking and SKU limits

    It creates a APIM resource with external VNet with a Public IP along with a Funciton App on a private endpoint injected into the same VNet

    ```
    az account set --subscription <subscriptionid>
    
    az group create --name rg-chapter4 --location <location>

    az deployment group create --resource-group rg-chapter4 --template-file ./chapter-4/bicep/funcapp-ip-apim.bicep
    ```

    Import the Function App and create a product, ensure that the API test works, the API is the standard Quickstart API which takes name=XXX as parameters

    Next create a product which includes this API, you may wich to untick the subscription option so thst no headers are required on testing


2. Create an Azure Cache for Redis Cache in the portal

    Use a .netcore app to put and get information to the cache

3. Create an event subscription against a storage account to fire a webhook when a blob is created

4. Create a Service Bus Namespace and a Service Bus Queue

    Optionally deploy an app to use the queue ( cannot be performed in Portal / CloudShell alone)

### Video 04_03 Hints

[Quickstart: Use Azure Cache for Redis in .NET Core](ttps://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-dotnet-core-quickstart)

[Use Azure Event Grid to route Blob storage events to web endpoint (Azure portal)](https://learn.microsoft.com/en-us/azure/event-grid/blob-event-quickstart-portal)

[Use Azure portal to create a Service Bus namespace and a queue](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-portal)

[Use a .net app to send messages to the queue](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dotnet-get-started-with-queues?tabs=passwordless%2Croles-azure-portal%2Csign-in-azure-cli%2Cidentity-visual-studio#send-messages-to-the-queue)

## Video 04_04 - Design migration

1. Create a virtual machine in Azure, then move it to another region

2. Create an Azure Migrate project

3. Explore adding assessment tools

4. Create an Azure Database Migration Service

    Explore the steps for [migrating SQL Server to Azure SQL](https://learn.microsoft.com/en-us/azure/dms/tutorial-sql-server-to-azure-sql)

    If possible setup SQL Server 2016 on a VM local to your laptop

5. Migrate a Azure SQL VM to Azure SQL Database with Data Migration Assistant

    You can create an Azure SQL VM pre-populated with Adevtureworks DB from the Portal

6. Explore the first two pages of settings for Azure Data Box

    Do not click to order!

### Video 04_04 Hints

[Move Azure VMs across regions](https://learn.microsoft.com/en-us/azure/resource-mover/tutorial-move-region-virtual-machines)

[Create and manage projects](https://learn.microsoft.com/en-us/azure/migrate/create-manage-projects)

[Add assessment tools](https://learn.microsoft.com/en-us/azure/migrate/how-to-assess)

[Create an instance of the Azure Database Migration Service by using the Azure portal](https://learn.microsoft.com/en-us/azure/dms/quickstart-create-data-migration-service-portal)

[Migrate on-premises SQL Server or SQL Server on Azure VMs to Azure SQL Database using the Data Migration Assistant](https://learn.microsoft.com/en-us/sql/dma/dma-migrateonpremsqltosqldb?view=sql-server-ver16)

[Order Azure Data Box](https://learn.microsoft.com/en-us/azure/databox/data-box-deploy-ordered?tabs=portal)

# Video 04_05 and 04_06 Design network solutions

1. Create a VNet with 65,534 addresses and a single Subnet

2. Create two application security group (ASG) to group web servers an admin servers

3. Create an network security group

4. Add security rules to allow ports 80 and 443 for your web servers ASG

5. Add security rules to allow ports 339 for your admin servers ASG

6. Assign the NSG to the Subnet

7. Create two VMs one called webvm and one called adminvm, ensure the subnet is the one you created in step 1

8. Associate the ASGs create in Step 2 to their respective VMs

9. Test the filtering works

10. Create a second VNet

11. Peer the two VNets

12. Follow this tutorial to explore Azure Firewall

    [Deploy and configure Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/tutorial-firewall-deploy-portal)



## Video 04_05 & 04_06 Hints

[Filter network traffic](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-filter-network-traffic)

[Vnet Peering Tutorial](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-connect-virtual-networks-portal)
