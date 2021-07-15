# Variables 
$resourceGroup = "PocResourceGroup"
$location = "East US"
$vmName = "ServerEUS"

# user
$cred = Get-Credential -Message " username and password "

# Create a subnet 
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name subnet1 -AddressPrefix 192.168.1.0/24

# Create a vn
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name vneteus -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# Create a dns
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "publicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# rdp
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name RuleRDP  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create nsg
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name nsgUS -SecurityRules $nsgRuleRDP

# Create nic
$nic = New-AzNetworkInterface -Name nicUS -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create  vm details
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_DS1_v2 | `
Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2019-Datacenter -Version latest | `
Add-AzVMNetworkInterface -Id $nic.Id

# Create  vm
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig