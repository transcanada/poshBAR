$appcmd = "$env:windir\system32\inetsrv\appcmd.exe"

<#
    .DESCRIPTION
        Creates an AppPool in IIS and sets up the specified identity to run under.

    .EXAMPLE
        New-AppPool

    .PARAMETER appPoolName
        The name of the application pool.

    .PARAMETER appPoolIdentityType
        The type of identity you want the AppPool to run as, default is 'LocalSystem'. 

    .PARAMETER maxProcesses
        The number of Worker Processes this AppPool should spawn, default is 1.

    .PARAMETER username
        The Username that this app pool should run as.

    .PARAMETER password
        The password for the Username that this app pool should run as.

    .SYNOPSIS
        Will setup an App Pool with a Managed Runtime Version of 4.0 and it defaults to using an Identity of LocalSystem.
#>
function New-AppPool{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, position=0, ParameterSetName="b")] [Xml.XmlElement] $websiteSettings,
        [parameter(Mandatory=$true, position=0, ParameterSetName="a")] [string] $appPoolName,
        [parameter(Mandatory=$false,position=1, ParameterSetName="a")] [string] [ValidateSet('LocalSystem','LocalService','NetworkService','SpecificUser','ApplicationPoolIdentity')] $appPoolIdentityType = 'NetworkService',
        [parameter(Mandatory=$false,position=2, ParameterSetName="a")] [int] $maxProcesses = 1,
        [parameter(Mandatory=$false,position=3, ParameterSetName="a")] [string] $username,
        [parameter(Mandatory=$false,position=4, ParameterSetName="a")] [string] $password,
         
        [parameter(Mandatory=$false,position=5, ParameterSetName="a")]
        [parameter(Mandatory=$false,position=1, ParameterSetName="b")] [string] [ValidateSet('Integrated','Classic')] $managedPipelineMode = 'Integrated',
        
        [parameter(Mandatory=$false,position=6, ParameterSetName="a")]
        [parameter(Mandatory=$false,position=2, ParameterSetName="b")] [string] $managedRuntimeVersion = "v4.0",

        [parameter(Mandatory=$false,position=7, ParameterSetName="a")]
        [parameter(Mandatory=$false,position=3, ParameterSetName="b")] [switch] $alwaysRunning
    )

    if($PsCmdlet.ParameterSetName -eq 'b'){
        New-AppPool -appPoolName $($websiteSettings.appPool.name) -appPoolIdentityType $($websiteSettings.appPool.identityType) -maxProcesses $($websiteSettings.appPool.maxWorkerProcesses) -userName $($websiteSettings.appPool.userName) -password $($websiteSettings.appPool.password) -managedPipelineMode $managedPipelineMode -managedRuntimeVersion $managedRuntimeVersion -alwaysRunning:$alwaysRunning
        return
    }

    $exists = Confirm-AppPoolExists $appPoolName

    if (!$exists){
        Write-Host "Creating AppPool: $appPoolName" -NoNewLine
        $newAppPool = "$appcmd add APPPOOL"
        $newAppPool += " /name:$appPoolName"
        $newAppPool += " /processModel.identityType:$appPoolIdentityType"
        $newAppPool += " /processModel.maxProcesses:$maxProcesses"
        $newAppPool += " /managedPipelineMode:$managedPipelineMode"
        $newAppPool += " /managedRuntimeVersion:$managedRuntimeVersion"
        $newAppPool += ' /autoStart:true'
        $newAppPool += if($alwaysRunning.IsPresent) {' /startMode:AlwaysRunning'}
    
        if ( $appPoolIdentityType -eq "SpecificUser" ){
            $newAppPool += " /processModel.userName:$username"
            $newAppPool += " /processModel.password:$password"
        }

        Exec { Invoke-Expression  $newAppPool } -retry 10 | Out-Null
        Write-Host "`tDone" -f Green
    }else{
        Update-AppPool $appPoolName $appPoolIdentityType $maxProcesses $username $password $managedPipelineMode $managedRuntimeVersion $alwaysRunning
    }
}    

function Update-AppPool{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, position=0)] [string] $appPoolName,
        [parameter(Mandatory=$false,position=1)] [string] [ValidateSet('LocalSystem','LocalService','NetworkService','SpecificUser','ApplicationPoolIdentity')] $appPoolIdentityType = 'NetworkService',
        [parameter(Mandatory=$false,position=2)] [int] $maxProcesses = 1,
        [parameter(Mandatory=$false,position=3)] [string] $username,
        [parameter(Mandatory=$false,position=4)] [string] $password,
        [parameter(Mandatory=$false,position=5)] [string] [ValidateSet('Integrated','Classic')] $managedPipelineMode = 'Integrated',
        [parameter(Mandatory=$false,position=6)] [string] $managedRuntimeVersion = "v4.0",
        [parameter(Mandatory=$false,position=7)] [switch] $alwaysRunning
    )

    $exists = Confirm-AppPoolExists $appPoolName

    if ($exists){
        Write-Host "Updating AppPool: $appPoolName" -NoNewLine
        $updateAppPool = "$appcmd set APPPOOL $appPoolName"
        $updateAppPool += " /processModel.identityType:$appPoolIdentityType"
        $updateAppPool += " /processModel.maxProcesses:$maxProcesses"
        $updateAppPool += " /managedPipelineMode:$managedPipelineMode"
        $updateAppPool += " /managedRuntimeVersion:$managedRuntimeVersion"
        $updateAppPool += ' /autoStart:true'
        $updateAppPool += if($alwaysRunning.IsPresent) {' /startMode:AlwaysRunning'}
    
        if ( $appPoolIdentityType -eq "SpecificUser" ){
            $updateAppPool += " /processModel.userName:$username"
            $updateAppPool += " /processModel.password:$password"
        }

        Exec { Invoke-Expression  $updateAppPool } -retry 10 | Out-Null
        Write-Host "`tDone" -f Green
    }else{
        Write-Warning ($msgs.wrn_invalid_app_pool -f $appPoolName)
    }
}

function Confirm-AppPoolExists( $appPoolName ){
    $getAppPool = Get-AppPool($appPoolName)
    return ($getAppPool -ne $null)
}

function Get-AppPool( $appPoolName ){
    $getAppPools = "$appcmd list APPPOOL $appPoolName"
    return Invoke-Expression $getAppPools
}

function Get-AppPools{
    $getAppPools = "$appcmd list APPPOOLS"
    Invoke-Expression $getAppPools | Out-Null
}

function Start-AppPool( $appPoolName ){
    $getAppPools = "$appcmd start APPPOOL $appPoolName"
    return Invoke-Expression $getAppPools
}

function Stop-AppPool( $appPoolName ){
    $getAppPools = "$appcmd stop APPPOOL $appPoolName"
    return Invoke-Expression $getAppPools
}

function Remove-AppPool( $appPoolName ){
    $getAppPools = "$appcmd delete APPPOOL $appPoolName"
    return Invoke-Expression $getAppPools
}

function Get-ModuleDirectory {
    return Split-Path $script:MyInvocation.MyCommand.Path
}