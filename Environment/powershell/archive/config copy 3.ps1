# Load configuration - try multiple formats with auto-detection
$ConfigFiles = @('.dotsrc', '.dots.json', '.dots.toml', '.dots.conf', 'config.json', 'dots.json')
$Config = @{}
$ConfigLoaded = $false

foreach ($configFile in $ConfigFiles) {
  $configPath = Join-Path $PSScriptRoot $configFile
  if (Test-Path $configPath) {
    try {
      $content = Get-Content $configPath -Raw

      # Auto-detect format by content and extension
      if (($content.Trim().StartsWith('{') -and $content.Trim().EndsWith('}')) -or $configFile -like '*.json') {
        # JSON format
        $Config = $content | ConvertFrom-Json -AsHashtable
        Write-Debug "Loaded JSON configuration from: $configPath"
        $ConfigLoaded = $true
        break
      }
      elseif ($configFile -like '*.toml') {
        # TOML format - not implemented yet
        Write-Error 'TOML support not yet implemented. Please use JSON format instead.'
        return
      }
      else {
        # Try JSON parsing anyway for files without clear extension
        try {
          $Config = $content | ConvertFrom-Json -AsHashtable
          Write-Debug "Loaded JSON configuration from: $configPath"
          $ConfigLoaded = $true
          break
        }
        catch {
          Write-Warning "Could not parse $configFile as JSON, trying next file..."
          continue
        }
      }
    }
    catch {
      Write-Warning "Failed to parse config file $configFile`: $_"
      continue
    }
  }
}

if (-not $ConfigLoaded) {
  Write-Error "No valid configuration file found. Expected one of: $($ConfigFiles -join ', ')"
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
    [array]$ExcludePatterns,
    [array]$LocalExcludePatterns = @()
  )

  # Combine global and local exclude patterns
  $allPatterns = @()
  if ($ExcludePatterns) { $allPatterns += $ExcludePatterns }
  if ($LocalExcludePatterns) { $allPatterns += $LocalExcludePatterns }

  if (-not $allPatterns -or $allPatterns.Count -eq 0) {
    return $false
  }

  foreach ($pattern in $allPatterns) {
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

  $localConfig = Get-LocalConfig -DirectoryPath $DirectoryPath

  if ($localConfig.loadOrder) {
    Write-Debug "$ctx_tag   Found load order in local config"
    return $localConfig.loadOrder
  }

  return $null
}

function Import-Script {
  param(
    [string]$ScriptPath,
    [int]$Depth = 0,
    [array]$LocalExcludes = @()
  )

  $indent = '  ' * ($Depth + 1)
  $fileName = Split-Path $ScriptPath -Leaf

  # Check exclusion patterns from both global and local config
  if (Test-ShouldExclude -Name $fileName -FullPath $ScriptPath -ExcludePatterns $Config.Excludes -LocalExcludePatterns $LocalExcludes) {
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

function Get-LocalConfig {
  param(
    [string]$DirectoryPath
  )

  # Get config files from config, or use defaults
  $configFiles = $Config.OrderFiles ?? @('.dotsrc', '.dots.json', '.dots.toml', '.dots.conf', '.dots.txt', 'config.json')

  foreach ($configFile in $configFiles) {
    $configPath = Join-Path $DirectoryPath $configFile
    if (Test-Path $configPath) {
      try {
        $content = Get-Content $configPath -Raw -ErrorAction SilentlyContinue

        # If file is empty, treat as skip
        if ([string]::IsNullOrWhiteSpace($content)) {
          return @{ skip = $true }
        }

        $content = $content.Trim()

        # Auto-detect format by content and extension
        if (($content.StartsWith('{') -and $content.EndsWith('}')) -or $configFile -like '*.json') {
          try {
            $localConfig = $content | ConvertFrom-Json
            return @{
              skip      = $localConfig.skip -eq $true
              excludes  = $localConfig.excludes ?? $localConfig.exclude ?? @()
              loadOrder = $localConfig.loadOrder ?? $localConfig.modules ?? $localConfig.order
            }
          }
          catch {
            # Not valid JSON, continue to text parsing
          }
        }

        # Handle as plain text
        if ($content -eq 'skip') {
          return @{ skip = $true }
        }

        # Plain text load order (not skip)
        $loadOrderItems = $content -split "`n" |
        Where-Object { $_ -and $_ -notmatch '^\s*#' -and $_.Trim() -ne '' -and $_.Trim() -ne 'skip' } |
        ForEach-Object { $_.Trim() }

        return @{
          skip      = $false
          loadOrder = $loadOrderItems
        }

      }
      catch {
        Write-Warning "$ctx_tag Failed to parse local config $configFile in $DirectoryPath`: $_"
      }
    }
  }

  return @{ skip = $false }
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

  # Get local configuration
  $localConfig = Get-LocalConfig -DirectoryPath $DirectoryPath

  # Check if directory should be excluded by global patterns
  if (Test-ShouldExclude -Name $dirName -FullPath $DirectoryPath -ExcludePatterns $Config.Excludes) {
    Write-Debug "$ctx_tag$indent ⊘ Skipped directory (global exclude): $dirName"
    return
  }

  # Check if directory should be skipped due to local config
  if ($localConfig.skip) {
    Write-Debug "$ctx_tag$indent ⊘ Skipped directory (local config): $dirName"
    return
  }

  Write-Debug "$ctx_tag$indent Loading: $dirName"

  # Show local excludes if any
  if ($localConfig.excludes -and $localConfig.excludes.Count -gt 0) {
    Write-Debug "$ctx_tag$indent Local excludes: $($localConfig.excludes -join ', ')"
  }

  # Check for custom load order
  $loadOrder = Get-LoadOrder -DirectoryPath $DirectoryPath

  if ($loadOrder) {
    Write-Debug "$ctx_tag$indent Using custom load order ($($loadOrder.Count) items)"
    Import-WithLoadOrder -DirectoryPath $DirectoryPath -LoadOrder $loadOrder -Depth $Depth -LocalExcludes $localConfig.excludes
  }
  else {
    Write-Debug "$ctx_tag$indent Using auto-discovery"
    Import-WithAutoDiscovery -DirectoryPath $DirectoryPath -Depth $Depth -LocalExcludes $localConfig.excludes
  }
}

function Import-WithLoadOrder {
  param(
    [string]$DirectoryPath,
    [array]$LoadOrder,
    [int]$Depth,
    [array]$LocalExcludes = @()
  )

  foreach ($item in $LoadOrder) {
    $itemPath = Join-Path $DirectoryPath $item

    # Handle different item types
    if ($item -like '*.ps1' -or $item -like '*.psm1') {
      # Direct script/module file
      if (Test-Path $itemPath -PathType Leaf) {
        Import-Script -ScriptPath $itemPath -Depth $Depth -LocalExcludes $LocalExcludes
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
        ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth -LocalExcludes $LocalExcludes }
      }
    }
    elseif ($item -like '*.*') {
      # File pattern in current directory
      Get-ChildItem -Path $DirectoryPath -Filter $item -File |
      Where-Object {
        ($_.Extension -eq '.ps1' -or $_.Extension -eq '.psm1')
      } |
      Sort-Object Name |
      ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth -LocalExcludes $LocalExcludes }
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
    [int]$Depth,
    [array]$LocalExcludes = @()
  )

  # Load .psm1 files first
  Get-ChildItem -Path $DirectoryPath -Filter '*.psm1' -File |
  Sort-Object Name |
  ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth -LocalExcludes $LocalExcludes }

  # Then load .ps1 files
  Get-ChildItem -Path $DirectoryPath -Filter '*.ps1' -File |
  Sort-Object Name |
  ForEach-Object { Import-Script -ScriptPath $_.FullName -Depth $Depth -LocalExcludes $LocalExcludes }

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
    elseif ($include.ContainsKey('modules') -and $include.modules.Count -eq 0) {
      # modules is empty array [] - load all modules
      Write-Debug "$ctx_tag modules is empty - loading all modules from $($include.path)"
      Import-DirectoryScripts -DirectoryPath $fullPath -Depth 0
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
