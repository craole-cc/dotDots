function Global:Get-WingetConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for the winget tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'winget'
  $name = 'winget'
  $cfg = 'config.toml'

  return @{
    cmd     = $cmd
    name    = $name
    desc    = if ($cmd -like $name) { "$name" } else { "$name ($cmd)" }
    conf    = @{
      dots = Join-Path $env:DOTS 'Configuration' $name $cfg
      user = Join-Path $env:USERPROFILE '.config' $cmd $cfg
    }
    envBase = ($cmd.ToUpper() + '_RC')
  }
}
$app = Get-WingetConfig
Write-Pretty -Tag 'TODO' -NoNewLine -As $($app.desc) 'Complete activate script.'

Import-Module -Name Microsoft.WinGet.CommandNotFound
