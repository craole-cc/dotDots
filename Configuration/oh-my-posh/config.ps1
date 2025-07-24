function Global:Invoke-OhMyPosh {
  [CmdletBinding()]
  param()

  $config = @{
    'OH_MY_POSH_RC' = Join-Path $env:DOTS 'Configuration' 'oh-my-posh' 'config.toml'
  }

  #{ Export environment variables
  foreach ($item in $config.GetEnumerator()) {
    if (Test-Path -Path $item.Value -PathType Leaf) {
      #{ Export environment variable
      [Environment]::SetEnvironmentVariable($item.Key, $item.Value, 'Process')
      Set-Variable -Name $item.Key -Value $item.Value -Scope Global
      Write-Verbose "Exported variable: $($item.Key) => $($item.Value)"
    }
  }

  #{ Initialize Oh My Posh
  if (-not $env:OH_MY_POSH_RC) {
    Write-Verbose 'No custom Oh My Posh config found, using the default'
    Write-Pretty -Tag 'Warn' `
      'No custom Oh My Posh config found, using the default'
    oh-my-posh init pwsh | Invoke-Expression
  }
  else {
    Write-Verbose "Using custom Oh My Posh config: $OH_MY_POSH_RC"
    Write-Pretty -DebugEnv 'OH_MY_POSH_RC' "$OH_MY_POSH_RC"
    oh-my-posh init pwsh --config $OH_MY_POSH_RC | Invoke-Expression
  }
}
