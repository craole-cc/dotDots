
# Load configuration - try both JSON and TOML
$ConfigPathJson = Join-Path $PSScriptRoot '.dots.json'
$ConfigPathToml = Join-Path $PSScriptRoot '.dots.toml'

$Config = @{}

if (Test-Path $ConfigPathJson) {
  try {
    $Config = Get-Content $ConfigPathJson -Raw | ConvertFrom-Json -AsHashtable
    Write-Debug "Loaded JSON configuration from: $ConfigPathJson"
  }
  catch {
    Write-Error "Failed to parse JSON config file: $_"
    return
  }
}
elseif (Test-Path $ConfigPathToml) {
  # For now, let's just tell the user to use JSON until we get a proper TOML parser
  Write-Error 'TOML support not yet implemented. Please use config.json instead.'
  return
}
else {
  Write-Error "No configuration file found. Expected: $ConfigPathJson or $ConfigPathToml"
  return
}

# Apply configuration settings
$Global:ctx_tag = $Config.Options.Tag ?? '>>= DOTS =<<'
$Global:Verbosity = $Config.Options.Verbosity ?? 'Info'
$Global:VerbosePreference = $Config.Options.VerbosePreference ?? 'SilentlyContinue'
$Global:DebugPreference = $Config.Options.DebugPreference ?? 'SilentlyContinue'
$Global:InformationPreference = $Config.Options.InformationPreference ?? 'SilentlyContinue'
$Global:WarningPreference = $Config.Options.WarningPreference ?? 'SilentlyContinue'
$Global:ErrorActionPreference = $Config.Options.ErrorActionPreference ?? 'Continue'

Write-Information "$ctx_tag Initializing PowerShell environment..."

#region Core Loading Functions

function Test-ShouldExclude {
  param(
    [string]$Name,
    [string]$FullPath,
    [array]$ExcludePatterns
  )

  if (-not $ExcludePatterns -or $ExcludePatterns.Count -eq 0) {
    return $false
  }

  foreach ($pattern in $ExcludePatterns) {
    # Handle wildcard patterns
    if ($pattern -like '*\**' -or $pattern -like '*?*') {
      if ($Name -like $pattern -or (Split-Path $FullPath -Leaf) -like $pattern) {
        Write-Debug "$ctx_tag   Excluded by pattern '$pattern': $Name"
        return $true
      }
    }
    # Handle string matching
    else {
      if ($Name -match $pattern -or $FullPath -match $pattern) {
        Write-Debug "$ctx_tag   Excluded by pattern '$pattern': $Name"
        return $true
      }
    }
  }

  return $false
}

function Get-LoadOrder {
  param(
    [string]$DirectoryPath
  )

  $orderFiles = @('.dots.toml', '.dots.json', 'dots.json', 'config.json', 'import.txt', 'load-order.txt')
  foreach ($orderFile in $orderFiles) {
    $orderPath = Join-Path $DirectoryPath $orderFile
    if (Test-Path $orderPath) {
      Write-Debug "$ctx_tag   Found load order file: $orderFile"
      try {
        if ($orderFile -like '*.json') {
          $configContent = Get-Content $orderPath -Raw | ConvertFrom-Json
          return $configContent.loadOrder ?? $configContent.modules ?? $configContent.order
        }
        else {
          return Get-Content $orderPath |
          Where-Object { $_ -and $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } |
          ForEach-Object { $_.Trim() }
        }
      }
      catch {
        Write-Warning "$ctx_tag Failed to parse $orderFile in $DirectoryPath`: $_"
      }
    }
  }

  return $null
}

function Import-Script {
  param(
    [string]$ScriptPath,
    [int]$Depth = 0
  )

  $indent = '  ' * ($Depth + 1)
  $fileName = Split-Path $ScriptPath -Leaf

  # Check exclusion patterns from config
  if (Test-ShouldExclude -Name $fileName -FullPath $ScriptPath -ExcludePatterns $Config.Excludes) {
    return
  }

  try {
    # Check for Export-ModuleMember in .ps1 files (should only be in .psm1)
    if ($ScriptPath -like '*.ps1') {
      $content = Get-Content $ScriptPath -Raw -ErrorAction SilentlyContinue
      if ($content -and $content -match 'Export-ModuleMember') {
        Write-Debug "$ctx_tag$indent ⊘ Skipped (Export-ModuleMember in .ps1): $fileName"
        return
      }
    }

    if ($ScriptPath -like '*.psm1') {
      Import-Module $ScriptPath -Force -Global -DisableNameChecking
      Write-Debug "$ctx_tag$indent ✓ $fileName (module)"
    }
    else {
      . $ScriptPath
      Write-Debug "$ctx_tag$indent ✓ $fileName (script)"
    }
  }
  catch {
    Write-Error "$ctx_tag$indent ✗ Failed to load $fileName`: $_"
  }
}

function Import-DirectoryScripts {
  param(
    [string]$DirectoryPath,
    [int]$Depth = 0
  )

  if (-not (Test-Path $DirectoryPath -PathType Container)) {
    return
  }

  $indent = '  ' * $Depth
  $dirName = Split-Path $DirectoryPath -Leaf

  # Check if directory should be excluded
  if (Test-ShouldExclude -Name $dirName -FullPath $DirectoryPath -ExcludePatterns $Config.Excludes) {
    Write-Debug "$ctx_tag$indent ⊘ Skipped directory: $dirName"
    return
  }

  Write-Debug "$ctx_tag$indent Loading: $dirName"

  # Check for custom load order
  $loadOrder = Get-LoadOrder -DirectoryPath $DirectoryPath

  if ($loadOrder) {
    Write-Debug "$ctx_tag$indent Using custom load order ($($loadOrder.Count) items)"
    Import-WithLoadOrder -DirectoryPath $DirectoryPath -LoadOrder $loadOrder -Depth $Depth
  }
  else {
    Write-Debug "$ctx_tag$indent Using auto-discovery"
    Import-WithAutoDiscovery -DirectoryPath $DirectoryPath -Depth $Depth
  }
}

function Import-WithLoadOrder {
  param(
    [string]$DirectoryPath,
    [array]$LoadOrder,
    [int]$Depth
  )

  foreach ($item in $LoadOrder) {
    $itemPath = Join-Path $DirectoryPath $item

    # Handle different item types
    if ($item -like '*.ps1' -or $item -like '*.psm1') {
      # Direct script/module file
      if (Test-Path $itemPath -PathType Leaf) {
        Import-Script -ScriptPath $itemPath -Depth $Depth
      }
      else {
        Write-Warning "$ctx_tag  Script not found: $item"
      }
    }
    elseif ($item -like '*/*' -or $item -like '*\*') {
      # Path pattern (e.g., "subfolder/*.ps1")
      $parentDir = Split-Path (Join-Path $DirectoryPath $item) -Parent
      $pattern = Split-Path $item -Leaf

      if (Test-Path $parentDir -PathType Container) {
        Get-ChildItem -Path $parentDir -Filter $pattern -File |
        Where-Object {
          ($_.Extension -eq '.ps1' -or $_.Extension -eq '.psm1')
        } |
        Sort-Object Name |
        ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth }
      }
    }
    elseif ($item -like '*.*') {
      # File pattern in current directory
      Get-ChildItem -Path $DirectoryPath -Filter $item -File |
      Where-Object {
        ($_.Extension -eq '.ps1' -or $_.Extension -eq '.psm1')
      } |
      Sort-Object Name |
      ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth }
    }
    else {
      # Directory name - case insensitive search
      $matchingDirs = Get-ChildItem -Path $DirectoryPath -Directory |
      Where-Object { $_.Name -ieq $item }

      if ($matchingDirs) {
        foreach ($dir in $matchingDirs) {
          Import-DirectoryScripts -DirectoryPath $dir.FullName -Depth ($Depth + 1)
        }
      }
      else {
        Write-Warning "$ctx_tag  Directory not found: $item"
      }
    }
  }
}

function Import-WithAutoDiscovery {
  param(
    [string]$DirectoryPath,
    [int]$Depth
  )

  # Load .psm1 files first
  Get-ChildItem -Path $DirectoryPath -Filter '*.psm1' -File |
  Sort-Object Name |
  ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth }

  # Then load .ps1 files
  Get-ChildItem -Path $DirectoryPath -Filter '*.ps1' -File |
  Sort-Object Name |
  ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth }

  # Finally, process subdirectories
  Get-ChildItem -Path $DirectoryPath -Directory |
  Sort-Object Name |
  ForEach-Object { Import-DirectoryScripts -DirectoryPath $_.FullName -Depth ($Depth + 1) }
}

#endregion

#region Main Execution

# Process includes
if ($Config.Includes -and $Config.Includes.Count -gt 0) {
  Write-Debug "$ctx_tag Found $($Config.Includes.Count) include configurations"

  foreach ($include in $Config.Includes) {
    $fullPath = Join-Path $env:DOTS $include.path

    Write-Debug "$ctx_tag Processing path: $($include.path) => $fullPath"

    if (-not (Test-Path $fullPath -PathType Container)) {
      Write-Warning "$ctx_tag Path not found: $fullPath"
      continue
    }

    # Add to PSModulePath
    $env:PSModulePath = $fullPath + [IO.Path]::PathSeparator + $env:PSModulePath

    # Set environment variables
    $pathParts = $include.path -split '\\'
    $envVarName = "DOTS_$($pathParts[0].ToUpper())"
    $basePath = Join-Path $env:DOTS $pathParts[0]

    [Environment]::SetEnvironmentVariable($envVarName, $basePath, 'Process')
    [Environment]::SetEnvironmentVariable("${envVarName}_PS", $fullPath, 'Process')
    Set-Variable -Name $envVarName -Value $basePath -Scope Global
    Set-Variable -Name "${envVarName}_PS" -Value $fullPath -Scope Global

    Write-Debug "$ctx_tag $envVarName => $basePath"
    Write-Debug "$ctx_tag ${envVarName}_PS => $fullPath"

    # Load specified modules
    if ($include.modules -and $include.modules.Count -gt 0) {
      Write-Debug "$ctx_tag Loading $($include.modules.Count) modules: $($include.modules -join ', ')"

      foreach ($moduleName in $include.modules) {
        if ([string]::IsNullOrWhiteSpace($moduleName)) {
          continue
        }

        Write-Debug "$ctx_tag Looking for module: $moduleName"
        $modulePath = Get-ChildItem -Path $fullPath -Directory |
        Where-Object { $_.Name -ieq $moduleName } |
        Select-Object -First 1

        if ($modulePath) {
          Write-Debug "$ctx_tag Found module directory: $($modulePath.FullName)"
          Import-DirectoryScripts -DirectoryPath $modulePath.FullName -Depth 1
        }
        else {
          Write-Warning "$ctx_tag Module not found: $moduleName in $fullPath"
        }
      }
    }
    else {
      Write-Debug "$ctx_tag No modules specified for $($include.path) - skipping"
    }
  }
}
else {
  Write-Warning "$ctx_tag No includes defined in configuration"
}

Write-Information "$ctx_tag PowerShell profile loaded successfully"

#endregion
