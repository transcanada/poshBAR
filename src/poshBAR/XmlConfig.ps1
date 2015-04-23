<#
    .DESCRIPTION
        Will parse an XML config file and replace the values at a xpath expression with the value passed in.

    .EXAMPLE
        Update-ConfigValues "C:\temp\somefile.config" "//SomeNode/AnotherNode" "Some New Value"

    .PARAMETER configFile
        A path to a file that is XML based

    .PARAMETER xpath
        Any valid XPath exression, wether result in 1 or many matches, wether a Element or and Attribute.

    .PARAMETER value
        Any valid XML value that you wish to set.

    .SYNOPSIS
        Updates a XML file with the value specified at the XPath expression specified..

    .NOTES
        Nothing yet...
#>
function Update-XmlConfigValues
{
    [CmdletBinding()]
    param( 
        [parameter(Mandatory=$true,position=0)] [string] $configFile,
        [parameter(Mandatory=$true,position=1)] [string] $xpath,
        [parameter(Mandatory=$true,position=2)] [AllowEmptyString()] [string] $value,
        [parameter(Mandatory=$false,position=3)] [string] $attributeName
    )

    $ErrorActionPreference = "Stop"

    $doc = New-Object System.Xml.XmlDocument;
    $doc.Load($configFile)

    $nodes = $doc.SelectNodes($xpath)

    $private:count = 0
 
    foreach ($node in $nodes) {
        if ($node -ne $null) {
            $private:count++

            if ($attributeName) {
                if ($node.HasAttribute($attributeName)) {
                    $node.SetAttribute($attributeName, $value)
                    Write-Host ($msgs.msg_updated_to -f "$xpath->$attributeName", $value)
                } else {
                    $node.SetAttribute($attributeName, $value)  
                    Write-Host ($msgs.msg_updated_to -f "$xpath->$attributeName", $value)
                }
            } else {
                if ($node.NodeType -eq "Element") {
                    $node.InnerXml = $value
                }
                else {
                    $node.Value = $value
                }
                #write message
                Write-Host ($msgs.msg_updated_to -f "$xpath", $value)
            }
        }
        else {
            #write message
            Write-Host ($msgs.msg_wasnt_found -f $xpath)
        }
    }

    if($private:count -eq 0) {
        #write message
        Write-Host ($msgs.msg_wasnt_found -f $xpath)
    }

    $doc.Save($configFile)
}

function Remove-XmlConfigValue
{
    [CmdletBinding()]
    param( 
        [parameter(Mandatory=$true,position=0)] [string] $configFile,
        [parameter(Mandatory=$true,position=1)] [string] $xpath
    )
	
    $ErrorActionPreference = "Stop"
	
    $doc = New-Object System.Xml.XmlDocument;
    $doc.Load($configFile)

    $nodes = $doc.SelectNodes($xpath)
 
    foreach ($node in $nodes) {
        if ($node -ne $null) {			
            $node.ParentNode.RemoveChild($node)
		}
	}
    $doc.Save($configFile)
}
function Update-XmlConfigAttributes
{
    [CmdletBinding()]
    param( 
        [parameter(Mandatory=$true,position=0)] [string] $configFile,
        [parameter(Mandatory=$true,position=1)] [string] $xpath,
        [parameter(Mandatory=$true,position=3)] [hashtable] $attributes
    )

    $ErrorActionPreference = "Stop"

    $doc = New-Object System.Xml.XmlDocument;
    $doc.Load($configFile)

    $nodes = $doc.SelectNodes($xpath)

    $private:count = 0
 
    foreach ($node in $nodes) {
        if ($node -ne $null) {
            $private:count++

            foreach($attributekey in $attributes.Keys)
            {
                if ($node.HasAttribute($attributekey)) {
                    $node.SetAttribute($attributekey, $attributes[$attributekey])
                    #write message
                    Write-Host ($msgs.msg_updated_to -f "$xpath->$attributeName", $attributes[$attributekey])
                } else {
                    $node.SetAttribute($attributekey, $attributes[$attributekey])
                    #write message
                    Write-Host ($msgs.msg_updated_to -f "$xpath->$attributeName", $attributes[$attributekey])
                }
            }
        }
        else {
            #write message
            Write-Host ($msgs.msg_wasnt_found -f $xpath)
        }
    }

    if($private:count -eq 0) {
        #write message
        Write-Host ($msgs.msg_wasnt_found -f $xpath)
    }

    $doc.Save($configFile)
}

<#
    .DESCRIPTION
        Will parse an XML config file and add a xml node at a xpath expression.

    .EXAMPLE
        Add-ConfigValues "C:\temp\somefile.config" "//SomeNode/AnotherNode" "SomeNewNode" @{"key0"="value0";"key1"="value1"}

    .PARAMETER configFile
        A path to a file that is XML based

    .PARAMETER xpath
        Any valid XPath exression, whether result in 1 or many matches, must be an Element.

    .PARAMETER newnode
        Any valid XML node name that you wish to add.

    .PARAMETER attributes
        Hashtable of attributes for the new node being created

    .SYNOPSIS
        Updates a XML file with the value specified at the XPath expression specified..

    .NOTES
        Nothing yet...
#>
function Add-XmlConfigValue
{
    [CmdletBinding()]
    param( 
        [parameter(Mandatory=$true,position=0)] [string] $configFile,
        [parameter(Mandatory=$true,position=1)] [string] $xpath,
        [parameter(Mandatory=$true,position=2)] [string] $newNode,        
        [parameter(Mandatory=$false,position=4)] [hashtable] $attributes
    )

    $ErrorActionPreference = "Stop"
    
    $doc = New-Object System.Xml.XmlDocument;
    $doc.Load($configFile)
    $nodes = $doc.SelectNodes($xpath)

    foreach ($node in $nodes) {
        if ($node -ne $null) {
			
			Write-Host "adding $newNode to node: $xpath"
			$nodeChild = $doc.CreateElement($newNode)
            $node.AppendChild($nodeChild) #| Out-Null
            if ($attributes)
            {
                foreach($attributekey in $attributes.Keys)
                {
                    $nodeChild.SetAttribute($attributekey, $attributes[$attributekey])
                }
            }        
        }
        else {
            Write-Host "$xpath wasn't found"
        }
    }
    $doc.Save($configFile) 
}

<#
    .DESCRIPTION
        Will parse an XML config file and add a xml section at a xpath expression.

    .EXAMPLE
        Add-ConfigValues "C:\temp\somefile.config" "//SomeNode/AnotherNode" "SomeNewNode" @{"key0"="value0";"key1"="value1"}

    .PARAMETER configFile
        A path to a file that is XML based

    .PARAMETER xpath
        Any valid XPath exression, whether result in 1 or many matches, must be an Element.

    .PARAMETER newnode
        Any valid XML node name that you wish to add.

    .PARAMETER attributes
        Hashtable of attributes for the new node being created

    .SYNOPSIS
        Updates a XML file with the value specified at the XPath expression specified..
        If the section already exists it will not create it but update it...
    .NOTES
        Nothing yet...
#>
function Add-XmlSection
{
    [CmdletBinding()]
    param( 
        [parameter(Mandatory=$true,position=0)] [string] $configFile,
        [parameter(Mandatory=$true,position=1)] [string] $xpath,
        [parameter(Mandatory=$true,position=2)] [string] $sectionName,        
        [parameter(Mandatory=$false,position=4)] [hashtable] $attributes
    )

    $ErrorActionPreference = "Stop"
    
    $doc = New-Object System.Xml.XmlDocument;
    $doc.Load($configFile)
    $nodes = $doc.SelectNodes($xpath)

    foreach ($node in $nodes) {
        if ($node -ne $null) {
			$nodeXpath = "$xpath/$sectionName"
            $nodeFound = $doc.SelectNodes($nodeXpath)

            if ($nodeFound.Count -eq 0)
            {
                $nodeChild = $doc.CreateElement($sectionName)
                $node.AppendChild($nodeChild) | Out-Null
            }
            else {			
                $nodeChild = $nodeFound[0]
            }
            if ($attributes)
            {
                foreach($attributekey in $attributes.Keys)
                {
                    $nodeChild.SetAttribute($attributekey, $attributes[$attributekey])
                }
            }        
        }
        else {
            Write-Host "$xpath wasn't found"
        }
    }

    $doc.Save($configFile) 
}

<#
    .DESCRIPTION
        Will transform one XML doc with another using the standard xdt transform

#>
function Invoke-XmlDocumentTransform
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=1)] 
        [string] $inputPathAndFile,
        
        [Parameter(Mandatory=$true, Position=2)]
        [string] $transformPathAndFile,
        
        [Parameter(Mandatory=$false, Position=3)] 
        [string] $outputPathAndFile
    )    
    Add-XmlTransformToPath

    Write-Host "Transforming '$inputPathAndFile' with '$transformPathAndFile'."
    $outputPathAndFile = if($outputPathAndFile) {$outputPathAndFile} else {$inputPathAndFile}
    Exec { xmltransform -i $inputPathAndFile -t $transformPathAndFile -o $outputPathAndFile } "Could not invoke xmltransform, make sure it's found in `$env:PATH."
}

function Add-XmlTransformToPath {

    if($env:Path -like '*xmltransform.*' ) { return }

    if($poshbar.XmlTransformPath -and (Test-Path $poshbar.XmlTransformPath)){

        $env:Path += ";$(Resolve-Path $poshbar.XmlTransformPath)"
        return
    }

    $here = Split-Path $script:MyInvocation.MyCommand.Path
    $packagePath = "$here\..\..\..\xmltransform.*\tools"
    if(Test-Path $packagePath) {
        $env:Path += ";$(Resolve-Path $packagePath)"
        return
    }

    $nuspecToolsPath = "$here\..\..\tools"
    if(Test-Path $nuspecToolsPath) {
        $env:Path += ";$(Resolve-Path $nuspecToolsPath)"
        return
    }

    throw 'Could not find XmlTransform, please specify it to `$poshbar["XmlTransformPath"]'
}

set-alias xdt Invoke-XmlDocumentTransform