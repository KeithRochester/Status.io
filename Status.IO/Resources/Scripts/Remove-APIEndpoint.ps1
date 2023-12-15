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
$APIEndPointClass = Get-SCOMClass -Name Status.IO.ApiEndPoint

$Connector = Get-SCOMConnector -DisplayName "Status.IO Connector"
if(!$Connector){
    Add-SCOMConnector -Name "Status.IO Connector" -DisplayName "Status.IO Connector" -Description "Connector used to submit discovery data"
    $Connector = Get-SCOMConnector -DisplayName "Status.IO Connector"
    }


$DiscoveryData = New-Object Microsoft.EnterpriseManagement.ConnectorFramework.IncrementalDiscoveryData

$APIEndPoint = New-Object Microsoft.EnterpriseManagement.Common.CreatableEnterpriseManagementObject($mg,$APIEndPointClass)

$APIEndPoint[$APIEndPointClass,"URL"].Value = $URL
$APIEndPoint[$APIEndPointClass,"ComponentNameRegEx"].Value = $ComponentNameRegEx
$APIEndPoint[$APIEndPointClass,"ContainerNameRegEx"].Value = $ContainerNameRegEx
$APIEndPoint[$APIEndPointClass,"Proxy"].Value = $Proxy
$APIEndPoint[$EntityClass,"DisplayName"].Value = $DisplayName

$DiscoveryData.Remove($APIEndPoint)
$DiscoveryData.Commit($Connector)
