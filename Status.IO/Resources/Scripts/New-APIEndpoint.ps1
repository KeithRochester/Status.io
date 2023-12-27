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
$URL = 'https://9498199887151372.hostedstatus.com/1.0/status/51f6f2088643809b7200000d'
$Proxy = "N/A"
$ComponentNameRegEx = 'United Kingdom'
$ContainerNameRegEx = '.'
$ManagementServer = '.'
#>

# Drop any proxy that doesn't match ^http
if($Proxy -match '^http'){
    $ProxyUseDefaultCredentials = $True
    # Request parameters for splatting
    $RequestParameters = @{
        'Uri' = $URL 
        'UseBasicParsing' = $True
        'UseDefaultCredentials' = $True
        'Proxy' = $Proxy
        'ProxyUseDefaultCredentials' = $ProxyUseDefaultCredentials
    }
}else{
# Request parameters for splatting
    $RequestParameters = @{
        'Uri' = $URL 
        'UseBasicParsing' = $True
        'UseDefaultCredentials' = $true
    }
}

try{
    $Request = Invoke-WebRequest @RequestParameters
    $RequestObjects = $Request.Content | ConvertFrom-Json    
}catch{
    $Request = $null
    $Success = $false
}

if($Request -ne $null){

    Add-PSSnapin Microsoft.EnterpriseManagement.OperationsManager.Client
    New-SCOMManagementGroupConnection -ComputerName $ManagementServer
    $MG = Get-SCOMManagementGroup


    $EntityClass = Get-SCOMClass -Name System.Entity
    $ApiEndpointClass = Get-SCOMClass -Name Status.IO.ApiEndpoint

    $Connector = Get-SCOMConnector -DisplayName "Status.IO Connector"
    if(!$Connector){
        Add-SCOMConnector -Name "Status.IO Connector" -DisplayName "Status.IO Connector" -Description "Connector used to submit discovery data"
        $Connector = Get-SCOMConnector -DisplayName "Status.IO Connector"
        }


    $DiscoveryData = New-Object Microsoft.EnterpriseManagement.ConnectorFramework.IncrementalDiscoveryData

    $ApiEndpoint = New-Object Microsoft.EnterpriseManagement.Common.CreatableEnterpriseManagementObject($mg,$ApiEndpointClass)

    $ApiEndpoint[$ApiEndpointClass,"URL"].Value = $URL
    $ApiEndpoint[$ApiEndpointClass,"ComponentNameRegEx"].Value = $ComponentNameRegEx
    $ApiEndpoint[$ApiEndpointClass,"ContainerNameRegEx"].Value = $ContainerNameRegEx
    $ApiEndpoint[$ApiEndpointClass,"Proxy"].Value = $Proxy
    $ApiEndpoint[$EntityClass,"DisplayName"].Value = $DisplayName

    $DiscoveryData.Add($ApiEndpoint)

    try{
        $DiscoveryData.Commit($Connector)
        $Success = $true
    }catch{
        $Success = $false
    }

}

if($Success){
    Write-host "Added Status.IO API Endpoint: $DisplayName"
    $ApiEndpoint.Values | FT @{L='Property';E={$_.Type}},Value
}else{
    Write-Host "Unabled to add Endpoint: `n $Error"
}
