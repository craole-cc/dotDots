function Global:Test-IsWindows {
  if ($IsWindows) {
    return $true
  }
  else {
    return $false
  }
}
function Global:Test-IsPowerShellCore {
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
function Global:Test-IsAdmin {
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

function Global:Test-GuiEnvironment {
  <#
    .SYNOPSIS
    Determines if a GUI environment is available for launching graphical editors

    .DESCRIPTION
    Intelligently detects GUI availability across different platforms and environments:
    - Windows: Always assumes GUI available (native desktop environment)
    - Unix/Linux: Checks for X11 (DISPLAY) or Wayland (WAYLAND_DISPLAY) environment variables
    - WSL: Detects GUI forwarding support (WSLg or X11 forwarding)

    This detection determines whether GUI editors (like VS Code, Zed) or TUI editors
    (like Helix, Neovim) should be prioritized in the selection process.

    .OUTPUTS
    [bool] True if GUI environment is detected, False for TUI-only environments

    .EXAMPLE
    Test-GuiEnvironment
    # Returns: True (on Windows or Linux with GUI)

    .EXAMPLE
    if (Test-GuiEnvironment) {
        Write-Host "GUI editors will be prioritized"
    } else {
        Write-Host "TUI editors only"
    }
    #>
  [CmdletBinding()]
  param()

  # Windows typically has GUI available
  if ($IsWindows -or $env:OS -like '*Windows*') {
    return $true
  }

  # Check for X11 or Wayland on Unix/Linux
  if ($env:DISPLAY -or $env:WAYLAND_DISPLAY) {
    return $true
  }

  # Check WSL with GUI support
  if ($env:WSL_DISTRO_NAME -and $env:DISPLAY) {
    return $true
  }

  return $false
}
