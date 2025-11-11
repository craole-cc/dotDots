<#
.SYNOPSIS
  Forcibly restarts the Windows Terminal application.
.DESCRIPTION
  A convenient shortcut that uses Restart-Program to forcefully terminate and
  then relaunch the Windows Terminal application.
.EXAMPLE
  Restart-WindowsTerminal
#>
function Global:Restart-WindowsTerminal {
  [CmdletBinding()]
  param()

  Restart-Application -Name 'WindowsTerminal' -LaunchCommand 'wt'
}

<#
.SYNOPSIS
  Forcibly stops the Windows Terminal application.
.DESCRIPTION
  A convenient shortcut that uses Stop-Application to forcefully terminate
  any running Windows Terminal processes.
.EXAMPLE
  Stop-WindowsTerminal
#>
function Global:Stop-WindowsTerminal {
  [CmdletBinding()]
  param()

  Stop-Application -Name 'WindowsTerminal'
}

function Global:Test-IsWindowsTerminal {
  [CmdletBinding()]
  param ()

  if ($PSVersionTable.PSVersion.Major -le 5 -or $IsWindows -eq $true) {
    $currentPid = $PID
    while ($currentPid) {
      try {
        $process = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction Stop -Verbose:$false
      }
      catch {
        return $false
      }
      if ($process.Name -eq 'WindowsTerminal.exe') {
        return $true
      }
      $currentPid = $process.ParentProcessId
    }
    return $false
  }
  else {
    return $false
  }
}
