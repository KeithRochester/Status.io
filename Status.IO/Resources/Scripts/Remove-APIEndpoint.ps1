[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True)]
	[string]$DisplayName,
	[Parameter(Mandatory = $True)]
	[String]$URL,
	[Parameter(Mandatory = $True)]
	[String]$Proxy,    
	[Parameter(Mandatory = $True)]
	[String]$ComponentNameRegEx,
	[Parameter(Mandatory = $True)]
	[String]$ContainerNameRegEx,
	[Parameter(Mandatory = $false)]
	[String]$ManagementServer = '.'

)

<#
$DisplayName = "Testing"
$URL = 'https://9498199887151372.hostedstatus.com/1.0/status/5d849b1c02e65b3ec45369d4'
$Proxy = "N/A"
$ComponentNameRegEx = 'United Kingdom'
$ContainerNameRegEx = '.'
$ManagementServer = '.'
#>

Add-PSSnapin Microsoft.EnterpriseManagement.OperationsManager.Client
New-SCOMManagementGroupConnection -ComputerName $ManagementServer
$MG = Get-SCOMManagementGroup


$EntityClass = Get-SCOMClass -Name System.Entity
$ApiEndpointClass = Get-SCOMClass -Name Status.IO.ApiEndpoint

$Connector = Get-SCOMConnector -DisplayName "Status.io Connector"
if(!$Connector){
    Add-SCOMConnector -Name "Status.io Connector" -DisplayName "Status.io Connector" -Description "Connector used to submit discovery data"
    $Connector = Get-SCOMConnector -DisplayName "Status.io Connector"
    }


$DiscoveryData = New-Object Microsoft.EnterpriseManagement.ConnectorFramework.IncrementalDiscoveryData

$ApiEndpoint = New-Object Microsoft.EnterpriseManagement.Common.CreatableEnterpriseManagementObject($mg,$ApiEndpointClass)

$ApiEndpoint[$ApiEndpointClass,"URL"].Value = $URL
$ApiEndpoint[$ApiEndpointClass,"ComponentNameRegEx"].Value = $ComponentNameRegEx
$ApiEndpoint[$ApiEndpointClass,"ContainerNameRegEx"].Value = $ContainerNameRegEx
$ApiEndpoint[$ApiEndpointClass,"Proxy"].Value = $Proxy
$ApiEndpoint[$EntityClass,"DisplayName"].Value = $DisplayName

$DiscoveryData.Remove($ApiEndpoint)
try{
    $DiscoveryData.Commit($Connector)
    $Success = $true
}catch{
    $Success = $false
}
if($Success){
    Write-host "Removed Status.io API Endpoint: $DisplayName"
    $ApiEndpoint.Values | FT @{L='Property';E={$_.Type}},Value
}
