function Test-IsWindows {
  if ($IsWindows) {
    return $true
  }
  else {
    return $false
  }
}
function Test-IsPowerShellCore {
  <#
  .SYNOPSIS
    Checks if the current PowerShell session is PowerShell Core (6+).

  .DESCRIPTION
    Returns $true if running PowerShell Core (version 6 or higher), otherwise $false.

  .OUTPUTS
    [bool] - $true if PowerShell Core, else $false.
  #>
  return $PSVersionTable.PSVersion.Major -ge 6
}
function Test-IsAdmin {
  if (Test-IsPowerShellCore) {
    #~@ Try using PowerShell Core/7+
    if ($IsWindows) {
      $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
      $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
      return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    return $false
  }
  else {
    #~@ Check using Windows Powershell
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }
}

Export-ModuleMember -Function @(
  'Test-IsAdmin',
  'Test-IsPowerShellCore',
  'Test-IsWindows'
)
