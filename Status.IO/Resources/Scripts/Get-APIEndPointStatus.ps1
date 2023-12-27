
[CmdletBinding()]
Param(

    [parameter(Mandatory=$true)]
    [string]$URL,

    [parameter(Mandatory=$true)]
    [string]$Proxy,

    [parameter(Mandatory=$true)]
    [string]$ComponentNameRegEx,

    [parameter(Mandatory=$true)]
    [string]$ContainerNameRegEx,

    [parameter(Mandatory=$true)]
    [string]$ApiEndpointId


)

<#
#Test Values

$URL = 'https://9498199887151372.hostedstatus.com/1.0/status/51f6f2088643809b7200000d'
$Proxy = $Null
$ComponentNameRegEx = '.'
$ContainerNameRegEx = '.'
$ApiEndpointId = {D9C625F2-AB77-968C-025E-A854E371244E}
#>

$Config = @{
    ScriptName = 'Get-APIEndpointStatus.ps1'
    EventNumber = 5101
}

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




# Create API Object
$API = New-Object -comObject 'MOM.ScriptApi'
    
try{
    $Request = Invoke-WebRequest @RequestParameters    
}catch{
    $Api.LogScriptEvent($Config.ScriptName ,$Config.EventNumber,1,"Invoke-WebRequest for $URL failed.")
}

try{
    $RequestObjects = $Request.Content | ConvertFrom-Json
}Catch{
    $Api.LogScriptEvent($Config.ScriptName ,$Config.EventNumber,1,"ConvertFrom-Json for $URL failed.")
}

# Create bag for endpoint
$Bag = $Api.CreatePropertyBag()
$Bag.AddValue("Endpoint_id", $ApiEndpointId.tostring() )
# Add Endpoint to bag
try{
    $RequestObjects.result.status_overall.psobject.properties.Name | % {
        $Bag.AddValue("Endpoint_$($_)", $RequestObjects.result.status_overall.$_.tostring() )
    }
}catch{
    $Bag.AddValue("Endpoint_status_code", (999).tostring() )
    $Bag.AddValue("Endpoint_status", "Unable to get status from API Endpoint" )
}

# Swap comment on last two lines to test outside of SCOM
#$api.Return($Bag) 
$Bag  

foreach($Component in ($RequestObjects.result.status | ? {$_.name -match $ComponentNameRegEx})){


    foreach($Container in $Component.containers | ? {$_.Name -match $ContainerNameRegEx}){
        
        # Create bag for each container
        $Bag = $Api.CreatePropertyBag()

        # Add container to bag
        $Container.psobject.properties.Name | % {
            $Bag.AddValue("Container_$($_)", $Container.$_.tostring() )
        }

        # Add Component to bag. 
        $Component.psobject.properties.Name | % {
            $Bag.AddValue("Component_$($_)", $Component.$_.tostring() )
        }

        # Swap comment on last two lines to test outside of SCOM
        #$api.Return($Bag) 
        $Bag            
    }
}

