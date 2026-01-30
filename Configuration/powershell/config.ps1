#Requires -Version 7.0

<#
.SYNOPSIS
    Configuration loader for dotDots PowerShell environment
.DESCRIPTION
    Loads configuration from various formats (.dotsrc, JSON, TOML, CONF)
    and applies settings to the PowerShell session
#>

using namespace System.Collections.Generic

#~@ Initialize configuration state
$Global:ConfigLoaded = $false
$Global:Config = $null
$Global:ctx_tag = '>>= DOTS =<<'

#region Helper Functions

function Get-ConfigProperty {
  <#
  .SYNOPSIS
      Gets a property with case-insensitive fallback for TOML compatibility
  #>
  param(
    [Parameter(Mandatory)]
    $Object,

    [Parameter(Mandatory)]
    [string]$PropertyName,

    $Default = @{}
  )

  $lowerProp = $PropertyName.ToLower()
  $upperProp = $PropertyName.Substring(0, 1).ToUpper() + $PropertyName.Substring(1)

  if ($Object.$lowerProp) { return $Object.$lowerProp }
  elseif ($Object.$upperProp) { return $Object.$upperProp }
  else { return $Default }
}

function Import-ConfigFile {
  <#
  .SYNOPSIS
      Loads and parses configuration file based on format
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
  )

  try {
    $content = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop

    switch -Wildcard ($ConfigPath) {
      '*.dotsrc' {
        Write-Debug "$ctx_tag Skipping shell-style .dotsrc"
        return $null
      }

      '*.json' {
        Write-Debug "$ctx_tag Parsing JSON (length: $($content.Length))..."
        try {
          $jsonObj = $content | ConvertFrom-Json -ErrorAction Stop
          Write-Debug "$ctx_tag Loaded JSON from: $ConfigPath"
          return $jsonObj
        }
        catch {
          Write-Error "$ctx_tag JSON parse error: $($_.Exception.Message)"
          return $null
        }
      }

      '*.conf' {
        Write-Debug "$ctx_tag Parsing CONF (length: $($content.Length))..."
        try {
          $confObj = [PSCustomObject]@{}
          $currentSection = 'root'
          $confObj | Add-Member -NotePropertyName $currentSection -NotePropertyValue ([PSCustomObject]@{})

          foreach ($line in ($content -split "`n")) {
            $line = $line.Trim()
            if ($line -match '^\[(.+)\]$') {
              $currentSection = $matches[1]
              if (-not ($confObj.PSObject.Properties.Name -contains $currentSection)) {
                $confObj | Add-Member -NotePropertyName $currentSection -NotePropertyValue ([PSCustomObject]@{})
              }
            }
            elseif ($line -match '^([^=]+)=(.*)$') {
              $key = $matches[1].Trim()
              $value = $matches[2].Trim()
              $confObj.$currentSection | Add-Member -NotePropertyName $key -NotePropertyValue $value -Force
            }
          }

          Write-Debug "$ctx_tag Loaded CONF from: $ConfigPath"
          return $confObj
        }
        catch {
          Write-Error "$ctx_tag CONF parse error: $($_.Exception.Message)"
          return $null
        }
      }

      '*.toml' {
        if (-not (Get-Module -ListAvailable -Name PSToml)) {
          Write-Debug "$ctx_tag Installing PSToml module..."
          try {
            Install-Module -Name PSToml -Scope CurrentUser -Force -ErrorAction Stop
          }
          catch {
            Write-Error "$ctx_tag Failed to install PSToml: $_"
            return $null
          }
        }

        try {
          Import-Module PSToml -ErrorAction Stop
          Write-Debug "$ctx_tag Parsing TOML (length: $($content.Length))..."
          $tomlTable = ConvertFrom-Toml -InputObject $content
          $configObj = [PSCustomObject]$tomlTable
          Write-Debug "$ctx_tag Loaded TOML from: $ConfigPath"
          return $configObj
        }
        catch {
          Write-Error "$ctx_tag TOML parse error: $($_.Exception.Message)"
          return $null
        }
      }

      default {
        Write-Warning "$ctx_tag Unknown config format: $ConfigPath"
        return $null
      }
    }
  }
  catch {
    Write-Error "$ctx_tag Failed to read config: $_"
    return $null
  }
}

#endregion

#region Main Configuration Loading

Write-Debug "$ctx_tag Loading configuration from: $PSCommandPath"

$ConfigFiles = @('.dotsrc', '.dots.json', 'dots.json', '.dots.conf', 'dots.conf', '.dots.toml', 'dots.toml')
$searchPaths = @($env:DOTS ?? $PSScriptRoot, $PSScriptRoot)

:configLoop foreach ($configFile in $ConfigFiles) {
  foreach ($searchPath in $searchPaths) {
    $configPath = Join-Path $searchPath $configFile
    if (Test-Path $configPath) {
      Write-Debug "$ctx_tag Found config: $configPath"
      $Config = Import-ConfigFile -ConfigPath $configPath

      if ($Config) {
        $Global:Config = $Config
        $Global:ConfigLoaded = $true
        Write-Debug "$ctx_tag Loaded config type: $($Config.GetType().Name)"
        break configLoop
      }
    }
  }
}

if (-not $ConfigLoaded) {
  Write-Error "$ctx_tag No valid configuration file found"
  return
}

#~@ Apply configuration settings
$opts = Get-ConfigProperty -Object $Config -PropertyName 'options'
$excl = Get-ConfigProperty -Object $Config -PropertyName 'excludes'
$ordr = Get-ConfigProperty -Object $Config -PropertyName 'order_files'
$git = Get-ConfigProperty -Object $Config -PropertyName 'git'

# Apply preference variables
$Global:ctx_tag = $opts.tag ?? $opts.Tag ?? '>>= DOTS =<<'
$Global:Verbosity = $opts.verbosity ?? $opts.Verbosity ?? 'Info'
$Global:VerbosePreference = $opts.verbosePreference ?? $opts.VerbosePreference ?? 'SilentlyContinue'
$Global:DebugPreference = $opts.debugPreference ?? $opts.DebugPreference ?? 'SilentlyContinue'
$Global:InformationPreference = $opts.informationPreference ?? $opts.InformationPreference ?? 'SilentlyContinue'
$Global:WarningPreference = $opts.warningPreference ?? $opts.WarningPreference ?? 'SilentlyContinue'
$Global:ErrorActionPreference = $opts.errorActionPreference ?? $opts.ErrorActionPreference ?? 'Continue'

Write-Information "$ctx_tag Initializing PowerShell environment..."
Write-Debug "$ctx_tag Verbosity: $Verbosity | Context: $ctx_tag"

# Store global patterns
$Global:ExcludePatterns = $excl.patterns ?? $excl.Patterns ?? @()
Write-Debug "$ctx_tag Exclude patterns: $($Global:ExcludePatterns.Count) items"

if ($ordr.filenames -or $ordr.Filenames) {
  $Global:ConfigFileOrder = $ordr.filenames ?? $ordr.Filenames
  Write-Debug "$ctx_tag Custom config order: $($Global:ConfigFileOrder -join ', ')"
}

# Apply git configuration
if ($git) {
  $env:GIT_USER = $git.user ?? $git.User ?? $env:GIT_USER
  $env:GIT_EMAIL = $git.email ?? $git.Email ?? $env:GIT_EMAIL
  $env:GIT_REPO = $git.repo ?? $git.Repo ?? $env:GIT_REPO
  Write-Debug "$ctx_tag Git: $env:GIT_USER <$env:GIT_EMAIL>"
}

Write-Debug "$ctx_tag Configuration loaded successfully"

#endregion

#region Process Includes

if ($Config.includes) {
  Write-Debug "$ctx_tag Processing $($Config.includes.Count) include sections..."

  foreach ($include in $Config.includes) {
    $basePath = Join-Path $env:DOTS $include.path
    Write-Debug "$ctx_tag Processing: $basePath"

    foreach ($moduleName in $include.modules) {
      $modulePath = Join-Path $basePath $moduleName

      if (-not (Test-Path $modulePath -PathType Container)) { continue }

      Write-Debug "$ctx_tag   Module: $moduleName"

      # Look for local config
      $localConfigPath = @('.dots.toml', '.dots.json', 'dots.json') |
      ForEach-Object { Join-Path $modulePath $_ } |
      Where-Object { Test-Path $_ } |
      Select-Object -First 1

      if ($localConfigPath) {
        Write-Debug "$ctx_tag     Config: $localConfigPath"
        $localConfig = Import-ConfigFile -ConfigPath $localConfigPath

        if ($localConfig) {
          $includesList = $localConfig.Includes ?? $localConfig.includes

          foreach ($file in $includesList) {
            if ($file -eq '_._') { continue }

            $filePath = Join-Path $modulePath $file

            # Skip directories
            if ((Test-Path $filePath -PathType Container) -or (-not $file.Contains('.'))) {
              Write-Debug "$ctx_tag       Skipping directory: $file"
              continue
            }

            if (Test-Path $filePath) {
              Write-Debug "$ctx_tag       Loading: $file"
              try {
                if ($file -like '*.psm1') {
                  Import-Module $filePath -Force -Global
                }
                else {
                  . $filePath
                }
              }
              catch {
                Write-Warning "$ctx_tag Failed to load ${file}: $_"
              }
            }
          }
        }
      }
      else {
        # No config - load all scripts
        Write-Debug "$ctx_tag     Loading all scripts (no config)"
        Get-ChildItem -Path $modulePath -Include '*.ps1', '*.psm1' -File -Recurse | ForEach-Object {
          Write-Debug "$ctx_tag       Loading: $($_.Name)"
          if ($_.Extension -eq '.psm1') {
            Import-Module $_.FullName -Force -Global
          }
          else {
            . $_.FullName
          }
        }
      }
    }
  }
}

#endregion

# Export module members
Export-ModuleMember -Variable @(
  'Config',
  'ConfigLoaded',
  'ctx_tag',
  'Verbosity',
  'ExcludePatterns',
  'ConfigFileOrder'
) -Function @(
  'Import-ConfigFile',
  'Get-ConfigProperty'
)
