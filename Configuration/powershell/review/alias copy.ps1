#@ Dynamic Path Aliases - Create cd.* and edit.* aliases for environment variables
#@ Usage: Place this in your PowerShell profile or dot-source it

#region Script Configuration
$script:ctx = if ($PSCommandPath) {
  [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
}
else {
  'PathAliases'
}
$script:ctxScope = 'Name'
$script:defaultEditor = $env:VISUAL ?? $env:EDITOR ?? 'code'
$script:skipVars = @(
  'PATH',
  'PATHEXT',
  'PSModulePath',
  'PROCESSOR_*',
  'NUMBER_OF_PROCESSORS',
  'OS',
  'COMPUTERNAME',
  'USERNAME',
  'USERDOMAIN*',
  'SESSIONNAME',
  'LOGONSERVER',
  '*ProgramFiles*',
  'WINDIR',
  'SYSTEMROOT',
  'COMSPEC',
  'ALLUSERSPROFILE'
)
#endregion

#region Core Functions
function Initialize-AliasEnvironment {
  [CmdletBinding()]
  param()

  # Validate Write-Pretty availability
  if (-not (Get-Command Write-Pretty -ErrorAction SilentlyContinue)) {
    function script:Write-Pretty {
      param(
        [string]$Tag = 'Info',
        [string]$ContextScope,
        [switch]$OneLine,
        [string]$Message
      )

      $color = switch ($Tag) {
        'Debug' { 'Cyan' }
        'Info' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
      }

      $prefix = if ($ContextScope) { "[$ContextScope] " } else { '' }
      Write-Host "$prefix$Message" -ForegroundColor $color
    }
  }

  Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "Initializing alias environment"
}

function Get-EnvVarsFromAllScopes {
  [CmdletBinding()]
  param()

  $allEnvVars = [ordered]@{}

  # Process scope takes highest precedence, then User, then Machine
  foreach ($scope in @('Machine', 'User', 'Process')) {
    try {
      $vars = [System.Environment]::GetEnvironmentVariables($scope)
      foreach ($var in $vars.GetEnumerator()) {
        # Only add if not already present (Process scope wins)
        if (-not $allEnvVars.ContainsKey($var.Key)) {
          $allEnvVars[$var.Key] = $var.Value
        }
      }
    }
    catch {
      Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Could not access $scope environment variables"
      continue
    }
  }

  return $allEnvVars
}

function Test-ShouldSkipVariable {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$VariableName
  )

  foreach ($skipPattern in $script:skipVars) {
    if ($VariableName -like $skipPattern) {
      return $true
    }
  }
  return $false
}

function New-AliasDynamic {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,
    [Parameter(Mandatory)]
    [string]$Value,
    [Parameter(Mandatory)]
    [ValidateSet('cd', 'edit')]
    [string]$Type
  )

  $expandedValue = try {
    [System.Environment]::ExpandEnvironmentVariables($Value)
  }
  catch {
    $Value
  }

  $aliasName = "$Type.$Name"

  # Create the function based on type
  if ($Type -eq 'cd') {
    $functionBody = @"
Set-Location -Path ([System.Environment]::ExpandEnvironmentVariables('$($Value.Replace("'", "''"))'))
Write-Host "Changed to: `$PWD" -ForegroundColor Green
"@
  }
  else {
    $functionBody = @"
`$editor = `$env:VISUAL ?? `$env:EDITOR ?? '$($script:defaultEditor)'
`$targetPath = [System.Environment]::ExpandEnvironmentVariables('$($Value.Replace("'", "''"))')
if (Test-Path `$targetPath) {
    Write-Host "Opening `$targetPath with `$editor" -ForegroundColor Green
    try {
        & `$editor `$targetPath
    }
    catch {
        Write-Warning "Failed to open `$targetPath with `$editor. Error: `$_"
    }
} else {
    Write-Warning "Path not found: `$targetPath"
}
"@
  }

  try {
    # Create the function in global scope
    $functionScript = "function global:$aliasName { $functionBody }"
    Invoke-Expression $functionScript

    Write-Pretty -Tag "Debug" -ContextScope $script:ctxScope -OneLine -Message "$aliasName => $expandedValue"
    return $true
  }
  catch {
    Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "Failed to create $Type alias for '$Name': $($_.Exception.Message)"
    return $false
  }
}

function Register-EnvironmentAliases {
  [CmdletBinding()]
  param()

  $envVars = Get-EnvVarsFromAllScopes
  $cdCount = 0
  $editCount = 0

  foreach ($envVar in $envVars.GetEnumerator()) {
    # Skip empty values
    if ([string]::IsNullOrWhiteSpace($envVar.Value)) { continue }

    # Skip system/unwanted variables
    if (Test-ShouldSkipVariable -VariableName $envVar.Key) { continue }

    try {
      $expandedValue = [System.Environment]::ExpandEnvironmentVariables($envVar.Value)

      # Create cd alias for directories
      if (Test-Path $expandedValue -PathType Container -ErrorAction SilentlyContinue) {
        if (New-AliasDynamic -Name $envVar.Key -Value $envVar.Value -Type 'cd') {
          $cdCount++
        }
      }

      # Create edit alias for any existing path (file or directory)
      if (Test-Path $expandedValue -ErrorAction SilentlyContinue) {
        if (New-AliasDynamic -Name $envVar.Key -Value $envVar.Value -Type 'edit') {
          $editCount++
        }
      }
    }
    catch {
      # Silently skip paths that can't be tested
      continue
    }
  }

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Created $cdCount 'cd.*' and $editCount 'edit.*' aliases"
}

function Register-PowerShellAliases {
  [CmdletBinding()]
  param()

  # Only register if $PROFILE exists
  if (-not $PROFILE) {
    Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "PowerShell profile variable not available"
    return
  }

  $profilePaths = @{
    'PROFILE'             = $PROFILE
    'PROFILE_ALLHOSTS'    = $PROFILE.AllUsersAllHosts
    'PROFILE_CURRENTUSER' = $PROFILE.CurrentUserAllHosts
    'PROFILE_CURRENTHOST' = $PROFILE.CurrentUserCurrentHost
    'PROFILE_ALLUSERS'    = $PROFILE.AllUsersCurrentHost
  }

  $profileCount = 0
  foreach ($profilePath in $profilePaths.GetEnumerator()) {
    if (-not [string]::IsNullOrWhiteSpace($profilePath.Value)) {
      if (New-AliasDynamic -Name $profilePath.Key -Value $profilePath.Value -Type 'edit') {
        $profileCount++
      }
    }
  }

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Created $profileCount PowerShell profile aliases"
}

function Register-PathAliases {
  [CmdletBinding()]
  param()

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Registering path aliases..."

  Register-EnvironmentAliases
  Register-PowerShellAliases

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Path alias registration complete. Use 'Show-PathAliases' to see available aliases."
}
#endregion

#region Utility Functions
function Global:Update-PathAliases {
  [CmdletBinding()]
  param()

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Refreshing path aliases..."

  # Remove existing aliases
  @('cd.*', 'edit.*') | ForEach-Object {
    Get-Command -Name $_ -CommandType Function -ErrorAction SilentlyContinue |
    ForEach-Object {
      Remove-Item -Path "Function:\$($_.Name)" -Force -ErrorAction SilentlyContinue
    }
  }

  Register-PathAliases
}

function Global:Show-PathAliases {
  [CmdletBinding()]
  param()

  $cdAliases = @(Get-Command -Name "cd.*" -CommandType Function -ErrorAction SilentlyContinue)
  $editAliases = @(Get-Command -Name "edit.*" -CommandType Function -ErrorAction SilentlyContinue)

  if ($cdAliases.Count -gt 0) {
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Available cd.* aliases ($($cdAliases.Count)):"
    $cdAliases | Sort-Object Name | ForEach-Object {
      Write-Host "  $($_.Name)" -ForegroundColor Green
    }
  }
  else {
    Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "No cd.* aliases found"
  }

  if ($editAliases.Count -gt 0) {
    Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Available edit.* aliases ($($editAliases.Count)):"
    $editAliases | Sort-Object Name | ForEach-Object {
      Write-Host "  $($_.Name)" -ForegroundColor Green
    }
  }
  else {
    Write-Pretty -Tag "Warning" -ContextScope $script:ctxScope -OneLine -Message "No edit.* aliases found"
  }
}

function Global:Remove-PathAliases {
  [CmdletBinding()]
  param()

  $removed = 0
  @('cd.*', 'edit.*') | ForEach-Object {
    Get-Command -Name $_ -CommandType Function -ErrorAction SilentlyContinue |
    ForEach-Object {
      Remove-Item -Path "Function:\$($_.Name)" -Force -ErrorAction SilentlyContinue
      $removed++
    }
  }

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Removed $removed path aliases"
}
#endregion

#region Main Execution
function Invoke-Main {
  [CmdletBinding()]
  param()

  try {
    Initialize-AliasEnvironment
    Register-PathAliases
  }
  catch {
    Write-Error "Failed to initialize path aliases: $($_.Exception.Message)"
  }
}

# Execute main function
Invoke-Main
#endregion
