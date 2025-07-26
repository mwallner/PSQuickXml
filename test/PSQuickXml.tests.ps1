
BeforeAll {
	$readQuick = Join-Path $PSScriptRoot '../src/Read-QuickXml.ps1'
	Set-Alias -Name Read-QuickXml -Value $readQuick -Force


	$xmlContent = @'
<root>
  <item id="1">foo</item>
  <item id="2">bar</item>
  <other>baz</other>
</root>
'@
	$tmpFile = New-TemporaryFile
	Set-Content -Path $tmpFile -Value $xmlContent
}

AfterAll { Remove-Item $tmpFile -ErrorAction SilentlyContinue }

Describe 'Read-QuickXml.ps1' {

	Context 'Without WantedNodes' {
		It 'Processes all nodes including text' {
			$r = [System.Collections.ArrayList]::new()
			Read-QuickXml -Path $tmpFile -OnNode { 
				param($node)
				$r.Add($node) | Out-Null
			}

			# Should include both element and text nodes
			$elementNames = $r | Where-Object { $_.NodeType -eq 'Element' } | Select-Object -ExpandProperty Name
			$textValues = $r | Where-Object { $_.NodeType -eq 'Text' } | Select-Object -ExpandProperty Value

			$elementNames | Should -Contain 'item'
			$elementNames | Should -Contain 'other'
			$textValues | Should -Contain 'foo'
			$textValues | Should -Contain 'bar'
			$textValues | Should -Contain 'baz'
		}
	}

	Context 'With WantedNodes' {
		It 'Processes only specified nodes and includes xml children' {
			$r = [System.Collections.ArrayList]::new()
			Read-QuickXml -Path $tmpFile -WantedNodes 'item' -OnNode { param($n) $r.Add($n) | Out-Null }

			$r.Count | Should -Be 2
			$r | ForEach-Object {
				$_.Name | Should -Be 'item'
				$_.Attributes.id | Should -Match '\d'
				$_.xml | Should -Not -BeNullOrEmpty
				# The xml property should be an array of XmlNode(s) with InnerText
				($_.xml | ForEach-Object { $_.InnerText }) | Should -Not -BeNullOrEmpty
			}
		}
		It 'Does not process text nodes when WantedNodes is set' {
			$r = [System.Collections.ArrayList]::new()
			Read-QuickXml -Path $tmpFile -WantedNodes item -OnNode { param($n) $r.Add($n) | Out-Null }
			($results | Where-Object { $_.NodeType -eq 'Text' }).Count | Should -Be 0
		}
	}
}
