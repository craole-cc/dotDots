function Global:Hello {
  [CmdletBinding()]
  param(
    [string]$name = "World"
  )
  
  Write-Host "Hello $name!"
}

Export-ModuleMember -Function Hello
