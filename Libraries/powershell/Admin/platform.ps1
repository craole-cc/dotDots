<#
.SYNOPSIS
    Utility functions for environment and platform detection.

.DESCRIPTION
    Provides a set of helper functions to determine:
    - Whether the OS is Windows
    - Whether the shell is PowerShell Core (6+)
    - Whether the current user has Administrator privileges
    - Whether a GUI environment is available
    - The current OS platform name

.NOTES
    Author: Craig
    Compatible with Windows PowerShell 5.1 and PowerShell Core / 7+
#>

function Global:Test-IsWindows {
  <#
    .SYNOPSIS
        Checks if the current OS is Windows.
    .OUTPUTS
        [bool]
    #>
  [CmdletBinding()]
  param()

  # Using -like 'win*' for resilience in case platform labels evolve (e.g., 'Win11', 'Windows10')
  return (Get-OSPlatform -like 'win*')
}

function Global:Test-IsPowerShellCore {
  <#
    .SYNOPSIS
        Checks if the current PowerShell session is PowerShell Core (6+).
    .OUTPUTS
        [bool]
    #>
  [CmdletBinding()]
  param()

  return ($PSVersionTable.PSVersion.Major -ge 6)
}

function Global:Test-IsAdmin {
  <#
    .SYNOPSIS
        Checks if the current user has Administrator/root privileges.
    .DESCRIPTION
        On Windows, checks if the current user token is in the Administrator role.
        On non-Windows platforms, always returns $false.
    .OUTPUTS
        [bool]
    #>
  [CmdletBinding()]
  param()

  if (-not (Test-IsWindows)) {
    return $false
  }

  try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  }
  catch {
    return $false
  }
}

function Global:Test-IsWsl {
  <#
    .SYNOPSIS
        Checks if the current environment is WSL (Windows Subsystem for Linux).
    .OUTPUTS
        [bool]
    #>
  [CmdletBinding()]
  param()

  try {
    return $env:WSL_DISTRO_NAME -or (
      (Get-Command uname -ErrorAction SilentlyContinue) -and
      ((uname -r) -match 'microsoft')
    )
  }
  catch {
    return $false
  }
}

function Global:Test-GuiEnvironment {
  <#
    .SYNOPSIS
        Determines if a GUI environment is available.
    .DESCRIPTION
        - Windows/macOS: assumed available
        - Linux: checks DISPLAY or WAYLAND_DISPLAY
        - WSL: checks DISPLAY forwarding
    .OUTPUTS
        [bool]
    #>
  [CmdletBinding()]
  param()

  switch (Get-OSPlatform) {
    'Windows' { return $true }
    'MacOS' { return $true }
    'Linux' { return ($env:DISPLAY -or $env:WAYLAND_DISPLAY) }
    'WSL' { return ($env:DISPLAY) }
    default { return $false }
  }
}

function Test-IsVSCode {
  return $env:VSCODE_PID -or
  ($env:TERM_PROGRAM -eq 'vscode') -or
  ($env:VSCODE_INJECTION -eq '1')
}

function Global:Get-OSPlatform {
  <#
    .SYNOPSIS
        Returns the current operating system platform as a string.
    .DESCRIPTION
        Detects the OS platform reliably across different PowerShell and .NET versions.
        Recognizes Windows, Linux, macOS, and WSL.
    .OUTPUTS
        [string] - 'Windows', 'Linux', 'MacOS', 'WSL', or 'Unknown'
    #>
  [CmdletBinding()]
  param()

  $label = @{
    win     = 'Windows'
    tux     = 'Linux'
    osx     = 'MacOS'
    wsl     = 'WSL'
    default = 'Unknown'
  }

  try {
    $runtime = [System.Runtime.InteropServices.RuntimeInformation]
    $os = [System.Runtime.InteropServices.OSPlatform]

    if ($runtime::IsOSPlatform($os::Windows)) { return $label.win }
    if ($runtime::IsOSPlatform($os::Linux)) {
      if (Test-IsWsl) { return $label.wsl }
      return $label.tux
    }
    if ($runtime::IsOSPlatform($os::OSX)) { return $label.osx }
  }
  catch {
    $fallback = [System.Environment]::OSVersion.Platform
    switch ($fallback) {
      { $_ -like 'Win*' } { return $label.win }
      'Unix' {
        if (Test-IsWsl) { return $label.wsl }
        return $label.tux
      }
      'MacOSX' { return $label.osx }
    }
  }

  return $label.default
}
