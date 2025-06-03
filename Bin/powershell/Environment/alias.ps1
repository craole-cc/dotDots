#region Configuration
function Set-Defaults {
  [CmdletBinding()]
  param()

  #| Context
  $Script:ctx = if ($PSCommandPath) {
    [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
  }
  else {
    'PathAliases'
  }
  $Script:ctxScope = 'Name'

  #| Editor
  if (-not (Get-Command Get-Editor -ErrorAction SilentlyContinue)) {
    # Write-Warning "Editor functions not loaded. Please source editor.ps1 first."
    $Script:defaultEditor = $env:VISUAL ?? $env:EDITOR ?? 'code'
  }
  else {
    $Script:defaultEditor = Get-PreferredEditor
  }

  #| Variables to Ignore
  $Script:excludedVars = @(
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

  $Script:specialVars = @{
    'PROFILE'             = $PROFILE
    'PROFILE_ALLHOSTS'    = $PROFILE.AllUsersAllHosts
    'PROFILE_CURRENTUSER' = $PROFILE.CurrentUserAllHosts
    'PROFILE_CURRENTHOST' = $PROFILE.CurrentUserCurrentHost
    'PROFILE_ALLUSERS'    = $PROFILE.AllUsersCurrentHost
  }

  $Script:envVars = Get-Env -Scope All
}

#endregion

#region Paths

function Register-PathAliases {
  [CmdletBinding()]
  param()

  #{ Generate aliases for all environment variables representing paths
  foreach ($var in $Script:envVars.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($var.Value)) { continue }
    if ($script:excludedVars | Where-Object { $var.Key -like $_ }) { continue }

    $envVar = $var.Key
    $envVal = [System.Environment]::ExpandEnvironmentVariables($var.Value)

    if (Test-Path $envVal -PathType Container) {
      Set-Env -Name $envVar -Value $envVal -Type "cd"
      Set-Env -Name $envVar -Value $envVal -Type "edit"
    }
    elseif (Test-Path $envVal) {
      Set-Env -Name $envVar -Value $envVal -Type "edit"
    }
    else {
      continue
    }
  }

  #{ Register PowerShell-specific profile paths
  foreach ($PSvar in $Script:specialVars.GetEnumerator()) {
    if (-not [string]::IsNullOrWhiteSpace($pSvar.Value)) {
      Set-Env -Name $PSvar.Key -Value $pSvar.Value -Type "edit"
    }
  }

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Use 'Show-PathAliases' to see available aliases."
}

function Update-PathAliases {
  [CmdletBinding()]
  param()

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Refreshing path aliases..."

  @('cd.*', 'edit.*') | ForEach-Object {
    Get-Command -Name $_ -CommandType Function -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item -Path "Function:\$($_.Name)" -Force }
  }

  Register-PathAliases
  Show-PathAliases
}

function Global:Show-PathAliases {
  [CmdletBinding()]
  param()

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Available cd.* aliases:"
  Get-Command -Name "cd.*" -CommandType Function |
  ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Green }

  Write-Pretty -Tag "Info" -ContextScope $script:ctxScope -OneLine -Message "Available edit.* aliases:"
  Get-Command -Name "edit.*" -CommandType Function |
  ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Green }
}

#endregion

#region Main
Set-Defaults
Register-PathAliases
#endregion
