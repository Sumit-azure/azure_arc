Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUsername,
    [string]
    $AzurePassword,
    [string]
    $DeploymentID,
    [string]
    $AppID,
    [string]
    $AppSecret,
    [string]
    $AzureTenantID,
    [string]
    $AzureSubscriptionID
)

$applicationId = 'b91cc0cf-dd39-4469-b8e7-c11e8e2ee5da'
$secret = 'pTc8Q~52.w5kgEKKNIOlLIRIdCSjGsykUSaTtdop' | ConvertTo-SecureString -AsPlainText -Force
$tenant1 = "b69eefee-f0a7-410b-b594-e4f23ba11195"
$tenant2 = $AzureTenantID
$cred = New-Object -TypeName PSCredential -ArgumentList $applicationId, $secret

#Clear-AzContext
Login-AzAccount -ServicePrincipal -Credential $cred  -Tenant $tenant1
Select-AzSubscription -Subscription 29c465b3-aedf-44db-8807-b933cd374bcc

Login-AzAccount -ServicePrincipal -Credential $cred -Tenant $tenant2

$DNS = "hciboxclient" + $DeploymentID
$resourceGroup = "AzurestackHCI"
$location = "eastus"
$vmName = "HCIBox-Client"

# Get the image. Replace the name of your resource group, gallery, and image definition. This will create the VM from the latest image version available.

$imageDefinitionID = "/subscriptions/29c465b3-aedf-44db-8807-b933cd374bcc/resourceGroups/cloudlabs-mgmt/providers/Microsoft.Compute/galleries/CloudLabsSIG/images/hcs-stack-hci/versions/latest"

# Create the network resources.

$subnetConfig = New-AzVirtualNetworkSubnetConfig `
   -Name default `
   -AddressPrefix 10.0.0.0/24

$vnet = New-AzVirtualNetwork `
   -ResourceGroupName $resourceGroup `
   -Location $location `
   -Name HybridHostHCI-vnet `
   -AddressPrefix 10.0.0.0/16 `
   -Subnet $subnetConfig

$pip = New-AzPublicIpAddress `
   -ResourceGroupName $resourceGroup `
   -Location $location `
  -Name HybridHostHCI-pip `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4 `
  -DomainNameLabel $DNS

$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
   -Name myNetworkSecurityGroupRuleRDP  `
   -Protocol Tcp `
   -Direction Inbound `
   -Priority 1000 `
   -SourceAddressPrefix * `
   -SourcePortRange * `
   -DestinationAddressPrefix * `
   -DestinationPortRange 3389 -Access Allow

$nsg = New-AzNetworkSecurityGroup `
   -ResourceGroupName $resourceGroup `
   -Location $location `
   -Name HybridHostHCI-nsg `
   -SecurityRules $nsgRuleRDP

$nic = New-AzNetworkInterface `
   -Name HybridHostHCI-nic `
   -ResourceGroupName $resourceGroup `
   -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration using Set-AzVMSourceImage -Id $imageDefinition.Id to use the latest available image version.

$vmConfig = New-AzVMConfig `
   -VMName $vmName `
   -VMSize Standard_E32s_v5  | `
   Set-AzVMSourceImage -Id $imageDefinitionId | `
   Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzVM `
   -ResourceGroupName $resourceGroup `
   -Location $location `
   -VM $vmConfig


Start-Sleep 180


$arguments = "$AzureUsername $AzurePassword $DeploymentID $AppID $AppSecret $AzureTenantID $AzureSubscriptionID"

    #Set-AzVMCustomScriptExtension -ResourceGroupName $resourceGroup -VMName $vmName -Name Installextension -FileUri https://experienceazure.blob.core.windows.net/templates/aiw-azure-arc-hybrid-cloud-solution/DT-setup/hci-customscript.ps1 -Run aiw-azure-arc-hybrid-cloud-solution/DT-setup/hci-customscript.ps1 -Argument $arguments -Location "eastus2" 
    
Start-Sleep 10
