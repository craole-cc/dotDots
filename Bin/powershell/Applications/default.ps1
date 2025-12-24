<#
.SYNOPSIS
  Forcibly stops and then restarts an application.
.DESCRIPTION
  This function finds all processes matching a given name, forcefully terminates them,
  and then starts a new instance of the application.
.PARAMETER Name
  The name of the process to restart (e.g., "notepad", "WindowsTerminal").
.PARAMETER LaunchCommand
  An optional command to use for launching the new instance. If not provided,
  the function will use the process name.
.EXAMPLE
  Restart-Application -Name "notepad"
  # Stops all notepad.exe processes and launches a new one.

.EXAMPLE
  Restart-Application -Name "WindowsTerminal" -LaunchCommand "wt"
  # Stops the WindowsTerminal process and relaunches it using the 'wt' command.

.EXAMPLE
  Restart-Application -Name "chrome" -WhatIf
  # Shows which processes would be stopped without actually stopping them.
#>
function Global:Restart-Application {
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [string]$LaunchCommand
  )

  try {
    $process = Get-Process -Name $Name -ErrorAction Stop
    if ($PSCmdlet.ShouldProcess($process.Name, 'Stop')) {
      Write-Host "Forcibly stopping process: $($process.Name) (PID(s): $($process.Id -join ', '))..."
      $process | Stop-Process -Force
      # Brief pause to allow the OS to release the process fully
      Start-Sleep -Milliseconds 500
    }
  }
  catch {
    Write-Host "Process '$Name' is not currently running."
  }

  $commandToRun = if ($LaunchCommand) { $LaunchCommand } else { $Name }

  if ($PSCmdlet.ShouldProcess($commandToRun, 'Start')) {
    Write-Host "Relaunching '$commandToRun'..."
    Start-Process $commandToRun
  }
}

<#
.SYNOPSIS
  Forcibly stops an application by its process name.
.DESCRIPTION
  This function finds all processes matching a given name and forcefully terminates them.
  It supports the -WhatIf parameter to show which processes would be stopped
  without actually stopping them.
.PARAMETER Name
  The name of the process to stop (e.g., "notepad", "WindowsTerminal").
.EXAMPLE
  Stop-Application -Name "notepad"
  # Stops all notepad.exe processes.

.EXAMPLE
  Stop-Application -Name "chrome" -WhatIf
  # Shows which Chrome processes would be stopped.
#>
function Global:Stop-Application {
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  $process = Get-Process -Name $Name -ErrorAction SilentlyContinue
  if ($process) {
    if ($PSCmdlet.ShouldProcess($process.Name, 'Stop')) {
      Write-Host "Forcibly stopping process: $($process.Name) (PID(s): $($process.Id -join ', '))..."
      $process | Stop-Process -Force
    }
  }
  else {
    Write-Host "Application '$Name' is not currently running."
  }
}
