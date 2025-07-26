<#
.SYNOPSIS
    Reads an XML file and processes nodes using a user-supplied script block.

.DESCRIPTION
    This script reads an XML file using a forward-only XmlReader for efficiency.
    For each node, it calls a user-supplied script block ($OnNode) with a hashtable describing the node.
    If the -WantedNodes parameter is specified, only nodes with those names are processed.
    When -WantedNodes is used, the hashtable includes an 'xml' property containing the children of the matched node as [xml] objects.

.PARAMETER Path
    The path to the XML file to read.

.PARAMETER OnNode
    A script block that will be called for each processed node. Receives a hashtable with node information.

.PARAMETER WantedNodes
    An optional array of node names to filter which nodes are processed. If not specified, all nodes are processed.

.EXAMPLE
    PS> .\Read-QuickXml.ps1 -Path 'input.xml' -OnNode { Write-Host $_ }
#>
[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string]$Path,

	[Parameter(Mandatory = $true)]
	[ScriptBlock]$OnNode,

	[Parameter()]
	[string[]]$WantedNodes
)

if (-not (Test-Path $Path)) {
	throw "File '$Path' does not exist."
}

$settings = New-Object System.Xml.XmlReaderSettings
$settings.IgnoreWhitespace = $true

$reader = [System.Xml.XmlReader]::Create($Path, $settings)

function Read-SubtreeXml {
	<#
    .SYNOPSIS
        Reads the current subtree from an XmlReader and returns it as an [xml] object.
    .PARAMETER reader
        The XmlReader positioned at the node to read.
    .OUTPUTS
        [xml]
    #>
	param ($reader)
	$subtree = $reader.ReadSubtree()
	$sw = New-Object System.IO.StringWriter
	$xw = New-Object System.Xml.XmlTextWriter($sw)
	$xw.Formatting = 'Indented'
	$subtree.Read() | Out-Null
	$xw.WriteNode($subtree, $true)
	$xw.Flush()
	$xmlString = $sw.ToString()
	$xw.Close()
	$sw.Close()
	return [xml]$xmlString
}

try {
	while ($reader.Read()) {
		switch ($reader.NodeType) {
			'Element' {
				$attributes = @{}
				if ($reader.HasAttributes) {
					for ($i = 0; $i -lt $reader.AttributeCount; $i++) {
						$reader.MoveToAttribute($i)
						$attributes[$reader.Name] = $reader.Value
					}
					$reader.MoveToElement() | Out-Null
				}

				$shouldProcess = -not $WantedNodes -or $WantedNodes -contains $reader.Name

				if ($shouldProcess) {
					$nodeHash = @{
						Name       = $reader.Name
						Depth      = $reader.Depth
						IsEmpty    = $reader.IsEmptyElement
						NodeType   = 'Element'
						Attributes = $attributes
					}
					if ($WantedNodes -and $WantedNodes -contains $reader.Name) {
						$xmlNode = Read-SubtreeXml $reader
						# Only include the children of the node, not the node itself
						$children = @()
						foreach ($child in $xmlNode.DocumentElement.ChildNodes) {
							$children += $child
						}
						$nodeHash['xml'] = $children
					}
					& $OnNode $nodeHash
				}
			}
			'Text' {
				if (-not $WantedNodes) {
					& $OnNode @{
						Name     = $reader.Name
						Depth    = $reader.Depth
						NodeType = 'Text'
						Value    = $reader.Value
					}
				}
			}
		}
	}
}
finally {
	$reader.Close()
}
