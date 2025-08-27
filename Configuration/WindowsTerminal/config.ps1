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
