function Global:Get-ScoopConfig {
  <#
    .SYNOPSIS
        Returns structured config variables for the scoop tool.
    #>
  [CmdletBinding()]
  param()

  $cmd = 'scoop'
  $name = 'scoop'
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
$app = Get-ScoopConfig
Write-Pretty -Tag 'TODO' -NoNewLine -As $($app.desc) 'Complete activate script.'
