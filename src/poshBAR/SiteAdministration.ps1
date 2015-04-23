$appcmd = "$env:windir\system32\inetsrv\appcmd.exe"

<#
    .DESCRIPTION
        Will create a Website with the specified settings if one doesn't exist.

    .EXAMPLE
        New-Site "myWebsite.com" "c:\inetpub\wwwroot" @{"protocol" = "http"; "port" = 80; "hostName"="mysite.com"} "myAppPool" -updateIfFound

    .EXAMPLE
        New-Site $websiteNode "c:\inetpub\wwwroot" "myAppPool" -updateIfFound

    .PARAMETER websiteSettings
        An xml node containing all of the required data for setting up a new site. See the NOTES section for more details.

    .PARAMETER siteName
        The name of the Website that we are creating.

    .PARAMETER sitePath
        The physical path where this Website is located on disk.

    .PARAMETER bindings
        An Object Array of bindings. Must include "protocol", "port", and "hostName"

    .PARAMETER appPoolName
        The name of the app pool to use

    .PARAMETER updateIfFound
        Should we update an existing website if it's found?
        
    .SYNOPSIS
        Will setup a web application under the specified Website and AppPool.

    .NOTES
        The $websiteSettings node is part of an opinionated xml structure used to house configuration data for environments.
#>
function New-Site{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,position=0, ParameterSetName="a")] [string] $siteName,
        [parameter(Mandatory=$true,position=0, ParameterSetName="b")] [Xml.XmlElement] $websiteSettings,
		
		[parameter(Mandatory=$true,position=1, ParameterSetName="a")]
        [parameter(Mandatory=$true,position=1, ParameterSetName="b")] [string] $sitePath,
		
        [parameter(Mandatory=$true,position=2, ParameterSetName="a")] [object[]] $bindings,
        [parameter(Mandatory=$true,position=3, ParameterSetName="a")] [string] $appPoolName,

        [parameter(Mandatory=$false,position=4, ParameterSetName="a")] 
        [parameter(Mandatory=$false,position=2, ParameterSetName="b")] [switch] $updateIfFound
    )

    if($PsCmdlet.ParameterSetName -eq 'b'){
        New-Site -siteName $($websiteSettings.siteName) -sitePath $sitePath -bindings $($websiteSettings.bindings) -appPoolName $($websiteSettings.appPool.name) $updateIfFound
        return
    }

    Write-Host "Creating Site: $siteName" -NoNewLine
    $exists = Confirm-SiteExists $siteName
    
    if (!$exists) {
        $bindingString = @()
        $bindings | % { $bindingString += "$($_.protocol)/*:$($_.port):$($_.hostName)" }
        Exec { Invoke-Expression  "$appcmd add site /name:$siteName /physicalPath:$sitePath /bindings:$($bindingString -join ",")"} -retry 10 | Out-Null
        Exec { Invoke-Expression  "$appcmd set app $siteName/ /applicationPool:$appPoolName"} -retry 10 | Out-Null
        Write-Host "`tDone" -f Green
    }else{
        Write-Host "`tExists" -f Cyan
        if ($updateIfFound.isPresent) {
            Update-Site $siteName $sitePath $bindings $appPoolName
        } else {
            # Message
            Write-Host ($msgs.msg_not_updating -f "Site")
        }
    }
}

function Update-Site{
    param(
            [parameter(Mandatory=$true,position=0)] [string] $siteName,
            [parameter(Mandatory=$true,position=1)] [string] $sitePath,
            [parameter(Mandatory=$true,position=3)] [object[]] $bindings,
            [parameter(Mandatory=$true,position=5)] [string] $appPoolName
    )

    Write-Host "Updating Site: $siteName" -NoNewLine
    $exists = Confirm-SiteExists $siteName

    if ($exists){
        $bindingString = @()
        $bindings | % { $bindingString += "$($_.protocol)/*:$($_.port):$($_.hostName)" }
        
        Exec { Invoke-Expression  "$appcmd set Site $siteName/ /bindings:$($bindingString -join ",")"} -retry 10  | Out-Null
        Exec { Invoke-Expression  "$appcmd set App $siteName/ /applicationPool:$appPoolName"} -retry 10 | Out-Null
        Exec { Invoke-Expression  "$appcmd set App $siteName/ `"/[path='/'].physicalPath:$sitePath`""} -retry 10 | Out-Null
        Write-Host "`tDone" -f Green
    }else{
        Write-Host "" #forces a new line
        Write-Warning ($msgs.cant_find -f "Site",$siteName)
    }
}

function Confirm-SiteExists( $siteName ){
    $getSite = Get-Site($siteName)
    return ($getSite -ne $null)
}

function Remove-Site( $siteName ){
    $getSite = "$appcmd delete App $siteName/"
    return Invoke-Expression $getSite
}

function Start-Site( $siteName ){
    $getSite = "$appcmd start App $siteName/"
    return Invoke-Expression $getSite
}

function Stop-Site( $siteName ){
    $getSite = "$appcmd stop App $siteName/"
    return Invoke-Expression $getSite
}

function Get-Site( $siteName ){
    $getSite = "$appcmd list App $siteName/"
    return Invoke-Expression $getSite
}

function Get-Sites{
    $getSite = "$appcmd list Apps"
    Invoke-Expression $getSite
}
