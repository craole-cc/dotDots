#~@ Define output messaging preferences
$Global:Verbosity = 'Quiet'
# $Global:VerbosePreference = 'Continue'
$Global:DebugPreference = 'Continue'
$Global:InformationPreference = 'Continue'
$Global:WarningPreference = 'Continue'
$Global:ErrorActionPreference = 'Continue'
$InitTime = Get-Date

#~@ Define path structure
$paths = [ordered]@{
  'DOTS_ENV' = Join-Path $env:DOTS 'Environment'
  'DOTS_DLD' = Join-Path $env:DOTS 'Import'
  'DOTS_MOD' = Join-Path $env:DOTS 'Modules'
  'DOTS_BIN' = Join-Path $env:DOTS 'Bin'
  'DOTS_CFG' = Join-Path $env:DOTS 'Configuration'
}

#~@ Define excluded folder patterns
$excludedPatterns = @(
  'review',
  'tmp',
  'temp',
  'archive',
  'backup'
) -join '|'

#~@ Add valid paths and load modules
foreach ($path in $paths.GetEnumerator()) {
  Write-Information "Processing path: $($path.Value)"
  if (Test-Path -Path $path.Value -PathType Container) {
    #~@ Export environment variable
    [Environment]::SetEnvironmentVariable($path.Key, $path.Value, 'Process')
    Set-Variable -Name $path.Key -Value $path.Value -Scope Global
    Write-Debug "$($path.Key) => $($path.Value)"

    #~@ Import modules recursively if the directory basename is powershell (excluding patterns)
    $pathPSValue = Join-Path $path.Value 'powershell'
    if (Test-Path -Path $pathPSValue -PathType Container) {
      #~@ Add to PSModulePath
      $env:PSModulePath = $path.Value + [IO.Path]::PathSeparator + $env:PSModulePath

      #~@ Create environment variable with name ($path.Key)_PS
      $pathPSKey = "$($path.Key)_PS"
      [Environment]::SetEnvironmentVariable($pathPSKey, $pathPSValue, 'Process')
      Set-Variable -Name $pathPSKey -Value $pathPSValue -Scope Global
      Write-Debug "$($pathPSKey) => $($pathPSValue)"

      #~@ Configure PowerShell experimental features if this is the config directory
      if ($path.Key -eq 'DOTS_CFG') {
        $configPath = Join-Path $pathPSValue 'config.json'

        #~@ Create config if it doesn't exist
        if (-not (Test-Path -Path $configPath -PathType Leaf)) {
          @'
{
    "ExperimentalFeatures": [
        "PSFeedbackProvider"
    ]
}
'@ | Set-Content -Path $configPath -Force
          Write-Warning "=== DOTS === Created PowerShell experimental features at: $configPath"
        }

        #~@ Verify features are enabled
        $experimentalFeatures = Get-ExperimentalFeature | Where-Object Enabled
        if ($experimentalFeatures) {
          Write-Warning "=== DOTS === Active experimental features:"
          $experimentalFeatures | ForEach-Object {
            Write-Warning "=== DOTS ===   • $($_.Name)"
          }
        }
        else {
          Write-Warning "=== DOTS === No experimental features active. Restart PowerShell to apply changes."
        }
      }

      #~@ Load all PowerShell modules recursively (excluding patterns)
      $modules = Get-ChildItem -Path $path.Value -Recurse -Include "*.psm1" |
      Where-Object { $_.FullName -notmatch $excludedPatterns }

      if ($modules) {
        Write-Debug "=== DOTS === Found $($modules.Count) module$(if($modules.Count -ne 1){'s'}) from $($path.Value)"
        $modules | ForEach-Object { Import-Module $_.FullName -Force }
      }
    }
  }
}

#~@ Print initialization message
Write-Pretty -Tag "Information" -As "DOTS" -Init $InitTime
