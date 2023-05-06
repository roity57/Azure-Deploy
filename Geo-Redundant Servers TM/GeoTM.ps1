# David Roitman - Create two resource groups with Azure FW, Internal LB & two VMs.  Ingest IP information for second Public IP defined and create Traffic Manager that fronts both private LBs.
# v1.0 - 6/5/2023
# Tested with Az Module 9.4.0 on Windows 10
# Utilises:
# https://learn.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-internal-bicep?tabs=CLI
# https://learn.microsoft.com/en-us/azure/firewall/quick-create-multiple-ip-bicep?tabs=CLI
# DOES NOT contain any error control for failures

#Specify the RGs being used
$rg1="Geo10"
$rg2="Geo20"

#******Specify the TM Profile name, needs to be unique******
$tmdns="mytm1"

New-AzResourceGroup -Name $rg1 -Location 'australiaeast'
New-AzResourceGroup -Name $rg2 -Location 'eastasia'

#Create each region 1 FW+DNAT, Internal LB & VMs
New-AzResourceGroupDeployment -ResourceGroupName $rg1 -TemplateFile ./azfwlb.bicep
New-AzResourceGroupDeployment -ResourceGroupName $rg2 -TemplateFile ./azfwlb.bicep

#Fetch the Public IP Addresses created from each of the Resource Groups
$rg1pip=Get-AzPublicIpAddress -ResourceGroupName $rg1
$rg2pip=Get-AzPublicIpAddress -ResourceGroupName $rg2

#Fetch the Id of the SECOND Public IP Address of each region
$endpoint1=$rg1pip[1].Id
$endpoint2=$rg2pip[1].Id

#Create TM Profile in initial Resource Group
New-AzTrafficManagerProfile -Name $tmdns -ResourceGroupName $rg1 -TrafficRoutingMethod Priority -MonitorProtocol "TCP" -RelativeDnsName $tmdns -Ttl 30 -MonitorPort 3389 -MonitorIntervalInSeconds 10 -MonitorTimeoutInSeconds 5
#Create two endpoints in the new TM profile
New-AzTrafficManagerEndpoint -Name "Primary" -ResourceGroupName $rg1 -ProfileName "$tmdns" -Type AzureEndpoints -TargetResourceId $endpoint1 -EndpointStatus "Enabled"
New-AzTrafficManagerEndpoint -Name "Failover" -ResourceGroupName $rg1 -ProfileName "$tmdns" -Type AzureEndpoints -TargetResourceId $endpoint2 -EndpointStatus "Enabled"