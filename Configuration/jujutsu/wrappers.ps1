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
        Pulls changes from remote using jj.
    .DESCRIPTION
        Fetches from remote origin and rebases jj state, then syncs with git.
    .PARAMETER Branch
        The branch to rebase onto (default: main@origin).
    #>
  [CmdletBinding()]
  param(
    [string]$Branch = 'main@origin'
  )

  Write-Pretty -NoNewLine -Tag 'Debug' 'Fetching and rebasing with jj...'
  jj git fetch --remote origin
  jj rebase --destination $Branch

  Write-Pretty -NoNewLine -Tag 'Info' 'Pull complete!'
}
function Global:Invoke-JujutsuPush {
  <#
    .SYNOPSIS
        Pushes changes to remote with jj.
    .PARAMETER Branch
        The bookmark/branch name to set and push (default: main).
    .PARAMETER AllowBackwards
        Allow backwards bookmark movement.
    .PARAMETER Force
        Force push even if remote changed.
    .PARAMETER Message
        Commit message for the push. Can be specified with -m, --message, or as remaining arguments.
    #>
  [CmdletBinding()]
  param(
    [string]$Branch = 'main',
    [Alias('b', 'back')]
    [switch]$AllowBackwards,
    [Alias('f')]
    [switch]$Force,
    [Parameter(ValueFromRemainingArguments)]
    [Alias('m', 'msg')]
    [string[]]$Message
  )

  Write-Pretty -NoNewLine -Tag 'Debug' 'Removing JJ lock if present...'
  Remove-Item -Path .jj/working_copy/working_copy.lock -ErrorAction SilentlyContinue

  # Join message text properly
  $messageText = if ($Message -and $Message.Count -gt 0) {
    ($Message | Where-Object { $_ -and $_ -notmatch '^-' } | ForEach-Object { $_.Trim() }) -join ' '
  } else {
    ''
  }

  # Check if working copy has changes
  Write-Pretty -NoNewLine -Tag 'Debug' 'Checking working copy status...'
  $emptyOutput = (jj log -r '@' --no-graph --color never -T 'empty' | Out-String).Trim()
  $isEmpty = $emptyOutput -eq 'true'

  if (-not $isEmpty) {
    # Working copy has changes - use jj new with message
    Write-Pretty -Tag 'Debug' 'Creating new commit from working copy...'
    if ($messageText) {
      jj new --message $messageText
    } else {
      jj new
    }
  } else {
    # Working copy is empty - use jj describe on parent
    Write-Pretty -Tag 'Debug' 'Working copy is empty, describing parent commit...'
    if ($messageText) {
      jj describe --revision '@-' --message $messageText
    } else {
      jj describe --revision '@-'
    }
  }

  Write-Pretty -Tag 'Debug' "Setting bookmark '$Branch'..."
  if ($AllowBackwards) {
    jj bookmark set $Branch --revision '@-' --allow-backwards
  } else {
    jj bookmark set $Branch --revision '@-'
  }

  Write-Pretty -Tag 'Debug' 'Updating the external repository...'
  if ($Force) {
    jj git push --bookmark $Branch --force
  } else {
    jj git push --bookmark $Branch
  }

  Write-Pretty -Tag 'Info' 'Push complete!'
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
  $backupPath = New-BackupCopy

  if ($backupPath) {
    Invoke-JujutsuPush -AllowBackwards -Force:$Force
    Write-Pretty -NoNewLine -Tag 'Success' "jjReup complete! Don't forget to delete the backup folder if everything looks good:"
    Write-Pretty -NoNewLine -Tag 'Debug' "  $backupPath"
  }
  else {
    Write-Pretty -NoNewLine -Tag 'Error' 'Backup failed, aborting push operation.'
  }
}

# -- Aliases
Set-Alias -Name jj-pull -Value Invoke-JujutsuPull -Scope Global -Force
Set-Alias -Name jj-push -Value Invoke-JujutsuPush -Scope Global -Force
Set-Alias -Name jj-reup -Value Invoke-JujutsuReup -Scope Global -Force
