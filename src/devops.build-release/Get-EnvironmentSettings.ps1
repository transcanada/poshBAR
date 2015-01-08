<#
    .DESCRIPTION
        Properly returns all the environmental settings for the particualr context in which this build is being run.

    .EXAMPLE
        $dbSettings = Get-EnvironmentSettings "ci" "//database"
        $value = $dbSettings.connectionString

    .PARAMETER environment
        The environment which this build is being run, these environments will match the names of the environments xml config files.  
        If a config file is found that matches the computer on which this is executing, it will use that instead.

    .PARAMETER nodeXPath
        A valid XPath expression that matches the set of values you are after.

    .PARAMETER culture
        If provided will look up settings for an environment based on culture information provided.

    .SYNOPSIS
        Will grab a set of values from the proper environment file and returns them as an object which you can reffer to like any other object.
        If there is a matching variable in the OctopusParameters, it will use that variable instead of the one located in the XML.

    .NOTES
        There MUST be a value present in the XML (even if it's empty). In order to override the value from Octopus. 
        If it's not represented in the XML, it will not be represented in the output of this method.
#>
function Get-EnvironmentSettings
{
    param(
        [parameter(Mandatory=$true,position=0)] [string] $environment,
        [parameter(Mandatory=$true,position=1)] [string] $nodeXPath = "/",
        [parameter(Mandatory=$false,position=3)] [string] $culture
    )

    $ErrorActionPreference = "Stop"

    $computerName = $env:COMPUTERNAME
    $doc = New-Object System.Xml.XmlDocument
    $currentDir = Split-Path $script:MyInvocation.MyCommand.Path

    if ( $culture ){
        $environmentsDir = Resolve-Path "$currentDir\..\environments\$culture"
    } else {
        $environmentsDir = Resolve-Path "$currentDir\..\environments"
    }

    if (Test-Path "$environmentsDir\$($computerName).xml") {
        Write-Host "Using config for machine '$computerName' instead of the '$environment' environment." -ForegroundColor Magenta
        $doc.Load("$environmentsDir\$($computerName).xml")
    } else {
        $doc.Load("$environmentsDir\$($environment).xml")
    }

    if($OctopusParameters){
        Write-Host "Checking for Octopus Overrides"
        foreach($key in $OctopusParameters.Keys)
        {
            $myXPath = "$nodeXPath/$($key.Replace(".", "/"))"
            try{
                $node = $doc.SelectSingleNode($myXPath)
            
                if($node){
                    Write-Host "Overriding node: '$key'`t`t Value: '$($OctopusParameters["$key"])'"
                    $node.InnerText = $($OctopusParameters["$key"])
                }
            } catch { 
                <# sometimes Octopus passes in crappy data #> 
            } finally {
                $node = $null
            }
        }
    }

    return $doc.SelectSingleNode($nodeXPath)
}