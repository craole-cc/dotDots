#~@ Define output messaging preferences
$Global:Verbosity = 'Warn' # Quiet, Error, Warn, Info, Debug, Trace
$Global:VerbosePreference = 'SilentlyContinue' #SilentlyContinue (default), Continue, Inquire, Stop
$Global:DebugPreference = 'SilentlyContinue'
$Global:InformationPreference = 'SilentlyContinue'
$Global:WarningPreference = 'SilentlyContinue'
$Global:ErrorActionPreference = 'Continue'
$ctx_tag = '>>= DOTS =<<'

#~@ Define path structure
$paths = [ordered]@{
  'DOTS_ENV' = Join-Path $env:DOTS 'Environment'
  'DOTS_DLD' = Join-Path $env:DOTS 'Import'
  'DOTS_BIN' = Join-Path $env:DOTS 'Bin'
  'DOTS_MOD' = Join-Path $env:DOTS 'Modules'
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
          Write-Warning "$ctx_tag Created PowerShell experimental features at: $configPath"
        }

        #~@ Verify features are enabled
        $experimentalFeatures = Get-ExperimentalFeature | Where-Object Enabled
        if ($experimentalFeatures) {
          Write-Warning "$ctx_tag Active experimental features:"
          $experimentalFeatures | ForEach-Object {
            Write-Warning "$ctx_tag   • $($_.Name)"
          }
        }
        else {
          Write-Warning '$ctx_tag No experimental features active. Restart PowerShell to apply changes.'
        }
      }

      #~@ Load all PowerShell modules recursively (excluding patterns)
      $modules = Get-ChildItem -Path $path.Value -Recurse -Include '*.psm1' |
      Where-Object { $_.FullName -notmatch $excludedPatterns }

      if ($modules) {
        $idx = $modules.Count
        $idx_tag = "module$(if($idx -ne 1){'s'})"
        $loc = $path.Value

        Write-Debug "$ctx_tag Processing $idx $idx_tag from $loc"
        # Write-Pretty -Tag 'Debug' Found $idx $idx_tag from $loc #TODO: This terminates the script, figure out a better way to handle this. It has to do with the fact that Write-Pretty is defined in Bin which is being loaded in this loop.
        $modules | ForEach-Object { Import-Module $_.FullName -Force }
      }
    }
  }
}
