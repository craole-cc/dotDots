<#
.SYNOPSIS
    Jujutsu (jj) workflow wrapper functions.

.DESCRIPTION
    Provides PowerShell wrapper functions for common jj workflows including
    pull, push, and reup operations. Requires Admin/backup.ps1 to be loaded.

.NOTES
    Author: Craig
    Place in Configuration/jujutsu/wrappers.ps1
#>

function Global:Invoke-JujutsuPull {
  <#
    .SYNOPSIS
        Pulls changes from remote using both jj and git.
    .DESCRIPTION
        Fetches from remote origin and rebases jj state, then pulls with git.
    #>
  [CmdletBinding()]
  param()

  Write-Host 'Fetching and rebasing with jj...' -ForegroundColor Cyan
  jj git fetch --remote origin
  jj rebase --destination main@origin

  # Write-Host 'Pulling with git...' -ForegroundColor Cyan
  # git checkout main
  # git pull origin main
}

function Global:Invoke-JujutsuPush {
  <#
    .SYNOPSIS
        Pushes changes to remote with jj and git.
    .PARAMETER AllowBackwards
        Allow backwards bookmark movement.
    .PARAMETER Force
        Force push even if remote changed.
    #>
  [CmdletBinding()]
  param(
    [switch]$AllowBackwards,
    [switch]$Force
  )

  Write-Host 'Removing JJ lock if present...' -ForegroundColor Cyan
  Remove-Item -Path .jj/working_copy/working_copy.lock -ErrorAction SilentlyContinue

  Write-Host 'Updating commit description...' -ForegroundColor Cyan
  jj describe

  Write-Host 'Setting bookmark and pushing with jj...' -ForegroundColor Cyan
  $backwardsFlag = if ($AllowBackwards) { '--allow-backwards' } else { '' }
  $forceFlag = if ($Force) { '--force' } else { '' }

  $jjBookmarkCmd = "jj bookmark set main --revision=@ $backwardsFlag".Trim()
  Invoke-Expression $jjBookmarkCmd

  $jjPushCmd = "jj git push $forceFlag".Trim()
  Invoke-Expression $jjPushCmd

  Write-Host 'Pushing with git...' -ForegroundColor Cyan
  $gitPushCmd = "git push origin main $forceFlag".Trim()
  Invoke-Expression $gitPushCmd

  Write-Host 'Push complete!' -ForegroundColor Green
}

function Global:Invoke-JujutsuReup {
  <#
    .SYNOPSIS
        Pull, backup, and push with allow-backwards in one operation.
    .DESCRIPTION
        Comprehensive workflow: pulls changes, creates backup, pushes with allow-backwards.
        Requires New-BackupCopy function from Admin/backup.ps1.
    .PARAMETER Force
        Force push even if remote changed.
    #>
  [CmdletBinding()]
  param(
    [switch]$Force
  )

  Invoke-JujutsuPull
  $backupPath = Backup-Path

  if ($backupPath) {
    Invoke-JujutsuPush -AllowBackwards -Force:$Force
    Write-Host "`n✓ Reup complete! Don't forget to delete the backup folder if everything looks good:" -ForegroundColor Yellow
    Write-Host "  $backupPath" -ForegroundColor Gray
  }
  else {
    Write-Error 'Backup failed, aborting push operation.'
  }
}

# Aliases
Set-Alias -Name jj-pull -Value Invoke-JujutsuPull -Scope Global -Force
Set-Alias -Name jj-push -Value Invoke-JujutsuPush -Scope Global -Force
Set-Alias -Name jj-reup -Value Invoke-JujutsuReup -Scope Global -Force
